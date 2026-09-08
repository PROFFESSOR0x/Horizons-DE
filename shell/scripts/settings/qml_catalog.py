"""Small source indexer for settings QML. Does not evaluate QML or its JavaScript."""
from dataclasses import dataclass, field
import re

@dataclass
class Node:
    kind: str
    start: int
    opening: int
    end: int = 0
    parent: object = None
    children: list = field(default_factory=list)

def mask(text):
    # Keep offsets/newlines, hide quoted strings and comments from brace scanning.
    result=list(text); i=0
    while i<len(text):
        end=None
        if text.startswith('//',i):
            end=text.find('\n',i)
            if end<0:end=len(text)
        elif text.startswith('/*',i):
            end=text.find('*/',i+2);end=len(text) if end<0 else end+2
        elif text[i]=='/' and (not text[:i].rstrip() or text[:i].rstrip()[-1] in '=(:,![&|?;{}' or text[:i].rstrip().endswith('return')):
            end=i+1;in_class=False
            while end<len(text):
                if text[end]=='\\':end+=2;continue
                if text[end]=='[':in_class=True
                if text[end]==']':in_class=False
                if text[end]=='/' and not in_class:end+=1;break
                end+=1
        elif text[i] in "\"'`":
            quote=text[i];end=i+1
            while end<len(text):
                if text[end]=='\\':end+=2;continue
                if text[end]==quote:end+=1;break
                end+=1
        if end is not None:
            for j in range(i,min(end,len(text))):
                if result[j]!='\n':result[j]=' '
            i=end
        else:i+=1
    return ''.join(result)

def parse(text):
    clean=mask(text);nodes=[];stack=[]
    opens={m.end()-1:(m.group(1),m.start()) for m in re.finditer(r'\b([A-Z][\w.]*)\s*\{',clean)}
    for i,c in enumerate(clean):
        if c=='{':
            node=None
            if i in opens:
                kind,start=opens[i];parent=next((n for n in reversed(stack) if n),None)
                node=Node(kind,start,i,parent=parent);nodes.append(node)
                if parent:parent.children.append(node)
            stack.append(node)
        elif c=='}':
            if not stack:raise ValueError('Unbalanced QML braces')
            node=stack.pop()
            if node:node.end=i+1
    if stack:raise ValueError('Unclosed QML braces')
    return nodes

def direct(text,node):
    data=list(text[node.opening+1:node.end-1])
    for child in node.children:
        for i in range(child.start-node.opening-1,child.end-node.opening-1):
            if data[i]!='\n':data[i]=' '
    return ''.join(data)

def label(text,node,properties='title|text|mainText|buttonText|placeholderText'):
    m=re.search(r'\b(?:'+properties+r')\s*:\s*Translation\.tr\(([\"\'])(.*?)\1\)',direct(text,node))
    return m.group(2) if m else ''
