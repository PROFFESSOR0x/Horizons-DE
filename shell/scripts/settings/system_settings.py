#!/usr/bin/env python3
"""OS settings bridge. Reads are unprivileged; mutations require interactive pkexec.

No operation runs on import. Passwords are handled by passwd in a terminal, never
by QML, JSON, process arguments or the shell's configuration file.
"""
import argparse
import configparser
import grp
import json
import os
from pathlib import Path
import pwd
import re
import shlex
import shutil
import subprocess
import sys
import tempfile

PAM = Path('/etc/pam.d')
SDDM = Path('/etc/sddm.conf')
BEGIN = '# BEGIN Horizons biometrics'
END = '# END Horizons biometrics'
SAFE_PATH = '/usr/sbin:/usr/bin:/sbin:/bin'


def run(args, **kw):
    return subprocess.run(args, check=True, text=True, **kw)


def read(path):
    try:
        return Path(path).read_text()
    except (OSError, UnicodeError):
        return ''


def users():
    minimum = re.search(r'^UID_MIN\s+(\d+)', read('/etc/login.defs'), re.M)
    minimum = int(minimum[1]) if minimum else 1000
    local = {line.split(':')[0] for line in read('/etc/passwd').splitlines()}
    admins = set()
    for name in ('wheel', 'sudo'):
        try:
            g = grp.getgrnam(name)
            admins.update(g.gr_mem)
            admins.update(p.pw_name for p in pwd.getpwall() if p.pw_gid == g.gr_gid)
        except KeyError:
            pass
    return [dict(name=p.pw_name, fullName=p.pw_gecos.split(',')[0], uid=p.pw_uid,
                 home=p.pw_dir, shell=p.pw_shell, administrator=p.pw_name in admins,
                 current=p.pw_uid == int(os.environ.get('PKEXEC_UID', os.getuid())))
            for p in pwd.getpwall() if minimum <= p.pw_uid < 65534 and p.pw_name in local]


def checked_user(name):
    if not re.fullmatch(r'[a-z_][a-z0-9_-]{0,31}', name):
        raise ValueError('Invalid user name')
    user = next((u for u in users() if u['name'] == name), None)
    if not user:
        raise ValueError('Only local human accounts can be changed')
    return user


def module(name):
    for base in ('/usr/lib/security', '/usr/lib64/security', '/lib/x86_64-linux-gnu/security', '/lib/security'):
        candidate = Path(base) / ('pam_' + name + '.so')
        if candidate.is_file():
            return str(candidate)
    return ''


def pam_base(text):
    if text.count(BEGIN) != text.count(END) or text.count(BEGIN) > 1:
        raise ValueError('Unrecognized managed authentication block')
    return re.sub(re.escape(BEGIN) + r'\n.*?' + re.escape(END) + r'\n?', '', text, flags=re.S)


def pam_supported(text):
    base = pam_base(text)
    auth = [line.strip() for line in base.splitlines() if re.match(r'^\s*-?auth\s', line)]
    # Do not prepend a sufficient module to custom MFA, jump rules or a managed
    # authselect stack. Only the simple distribution include layout is supported.
    return bool(auth) and all(re.fullmatch(r'auth\s+include\s+system-(?:auth|login)', line) for line in auth)


def pam_update(text, fingerprint, face):
    base = pam_base(text)
    if not pam_supported(base):
        raise ValueError('This PAM layout must be managed with the distribution authentication tool')
    lines = []
    for enabled, name in ((fingerprint, 'fprintd'), (face, 'howdy')):
        if enabled:
            path = module(name)
            if not path:
                raise ValueError('Authentication provider is not installed: ' + name)
            lines.append('auth sufficient ' + path)
    if not lines:
        return base
    # Keep every original password/account/session rule unchanged.
    block = BEGIN + '\n' + '\n'.join(lines) + '\n' + END + '\n'
    return block + base


def atomic_write(path, text):
    path = Path(path)
    if path.is_symlink():
        raise ValueError('Refusing to replace a symlink')
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        backup = path.with_name(path.name + '.horizons-backup')
        if not backup.exists():
            shutil.copy2(path, backup)
    fd, temporary = tempfile.mkstemp(prefix='.horizons-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, path.stat().st_mode & 0o777 if path.exists() else 0o644)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def sddm_config():
    config = configparser.ConfigParser(interpolation=None, strict=False)
    config.optionxform = str
    for folder in ('/usr/lib/sddm/sddm.conf.d', '/etc/sddm.conf.d'):
        config.read(sorted(Path(folder).glob('*.conf')))
    config.read(SDDM)
    return config


def manager():
    try:
        return Path('/etc/systemd/system/display-manager.service').resolve(strict=True).stem
    except OSError:
        return ''


def snapshot():
    config = sddm_config()
    authentication = {}
    for service in ('sudo', 'sddm'):
        text = read(PAM / service)
        block = re.search(re.escape(BEGIN) + r'\n(.*?)' + re.escape(END), text, re.S)
        block = block[1] if block else ''
        authentication[service] = dict(supported=pam_supported(text) and not Path('/etc/authselect/authselect.conf').exists(),
            fingerprint='pam_fprintd.so' in block, face='pam_howdy.so' in block)
    return dict(users=users(), manager=manager(), pkexec=bool(shutil.which('pkexec')),
                fingerprint=bool(shutil.which('fprintd-enroll')), face=bool(shutil.which('howdy')),
                fingerprintPam=bool(module('fprintd')), facePam=bool(module('howdy')),
                authentication=authentication,
                themes=sorted(p.name for p in Path('/usr/share/sddm/themes').glob('*') if p.is_dir()),
                sessions=sorted({p.name for d in ('/usr/share/wayland-sessions', '/usr/share/xsessions') for p in Path(d).glob('*.desktop')}),
                theme=config.get('Theme', 'Current', fallback=''),
                autoUser=config.get('Autologin', 'User', fallback=''),
                autoSession=config.get('Autologin', 'Session', fallback=''),
                rememberUser=config.getboolean('Users', 'RememberLastUser', fallback=True),
                rememberSession=config.getboolean('Users', 'RememberLastSession', fallback=True))


def apply(action, data):
    if os.geteuid() != 0:
        raise PermissionError('Administrator authentication is required')
    os.environ['PATH'] = SAFE_PATH
    if action == 'authentication':
        service = data['service']
        if service not in ('sudo', 'sddm') or (service == 'sddm' and manager() != 'sddm'):
            raise ValueError('Unsupported authentication service')
        if Path('/etc/authselect/authselect.conf').exists():
            raise ValueError('Use authselect on this system')
        if type(data['fingerprint']) is not bool or type(data['face']) is not bool:
            raise ValueError('Expected boolean authentication switches')
        target = PAM / service
        atomic_write(target, pam_update(read(target), data['fingerprint'], data['face']))
    elif action == 'login':
        if manager() != 'sddm':
            raise ValueError('This login manager is not supported yet')
        state = snapshot()
        theme, user, session = data['theme'], data['user'], data['session']
        if theme and theme not in state['themes']:
            raise ValueError('Choose an installed theme')
        if user:
            checked_user(user)
            if session not in state['sessions']:
                raise ValueError('Choose an installed session')
        config = configparser.ConfigParser(interpolation=None, strict=False)
        config.optionxform = str
        config.read(SDDM)
        for group in ('Theme', 'Autologin', 'Users'):
            if not config.has_section(group):
                config.add_section(group)
        config['Theme']['Current'] = theme
        config['Autologin'].update(User=user, Session=session if user else '', Relogin='false')
        config['Users']['RememberLastUser'] = 'true' if data['rememberUser'] else 'false'
        config['Users']['RememberLastSession'] = 'true' if data['rememberSession'] else 'false'
        import io
        buffer = io.StringIO()
        config.write(buffer, space_around_delimiters=False)
        atomic_write(SDDM, buffer.getvalue())
    elif action == 'create-user':
        name = data['name']
        if not re.fullmatch(r'[a-z_][a-z0-9_-]{0,31}', name):
            raise ValueError('Invalid user name')
        full = data.get('fullName', '')
        if len(full) > 128 or any(c in full for c in ':\n\r\0'):
            raise ValueError('Invalid full name')
        run(['useradd', '--create-home', '--comment', full, '--shell', '/bin/bash', name])
    elif action in ('rename-user', 'administrator', 'delete-user'):
        user = checked_user(data['name'])
        if action != 'rename-user' and user['current']:
            raise ValueError('Change another account to avoid locking yourself out')
        if action == 'rename-user':
            full = data['fullName']
            if len(full) > 128 or any(c in full for c in ':\n\r\0'):
                raise ValueError('Invalid full name')
            run(['usermod', '--comment', full, user['name']])
        elif action == 'administrator':
            groups = [g for g in ('wheel', 'sudo') if any(item.gr_name == g for item in grp.getgrall())]
            if not groups:
                raise ValueError('No supported administrator group exists')
            if data['enabled']:
                run(['usermod', '--append', '--groups', groups[0], user['name']])
            else:
                for group in groups:
                    g = grp.getgrnam(group)
                    if pwd.getpwnam(user['name']).pw_gid == g.gr_gid:
                        raise ValueError('Cannot remove a primary administrator group')
                    if user['name'] in g.gr_mem:
                        run(['gpasswd', '--delete', user['name'], group])
        else:
            # Never remove a home directory or terminate a logged-in session.
            run(['userdel', user['name']])
    else:
        raise ValueError('Unknown system settings action')


def terminal_action(action, name, finger='right-index-finger'):
    checked_user(name)
    if action == 'password':
        command = ['passwd', name] if pwd.getpwnam(name).pw_uid == os.getuid() else ['pkexec', 'passwd', name]
    elif action in ('fingerprint-enroll', 'fingerprint-list', 'fingerprint-delete', 'fingerprint-verify'):
        command = [action.replace('fingerprint', 'fprintd'), name]
        if action == 'fingerprint-enroll':
            if finger not in {hand + '-' + digit for hand in ('left','right') for digit in ('thumb','index-finger','middle-finger','ring-finger','little-finger')}:
                raise ValueError('Invalid finger')
            command = ['fprintd-enroll', '-f', finger, name]
    elif action in ('face-add', 'face-list', 'face-clear', 'face-test'):
        command = ['pkexec', 'howdy', '-U', name, action.removeprefix('face-')]
    else:
        raise ValueError('Unknown enrollment action')
    result = subprocess.run(command)
    print('\nExit status:', result.returncode)
    input('Press Enter to close / اضغط Enter للإغلاق… ')
    return result.returncode


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action')
    parser.add_argument('payload', nargs='?', default='{}')
    args = parser.parse_args()
    try:
        data = json.loads(args.payload)
        if args.action == 'status':
            print(json.dumps(snapshot(), ensure_ascii=False))
        elif args.action == 'terminal':
            command = shlex.split(data['terminal'])
            if not command or not shutil.which(command[0]):
                raise ValueError('Configured terminal is not installed')
            subprocess.Popen(command + ['-e', sys.executable, str(Path(__file__).resolve()), 'interactive', json.dumps(data)])
        elif args.action == 'interactive':
            return terminal_action(data['action'], data['name'], data.get('finger', 'right-index-finger'))
        else:
            apply(args.action, data)
            print(json.dumps({'ok': True}))
        return 0
    except (ValueError, KeyError, OSError, configparser.Error, subprocess.CalledProcessError) as error:
        print(json.dumps({'error': str(error)}, ensure_ascii=False))
        return 1


if __name__ == '__main__':
    sys.exit(main())
