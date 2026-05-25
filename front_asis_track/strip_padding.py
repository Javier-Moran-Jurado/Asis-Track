import os
import re

lib_dir = '/home/nicoguti/Almacenamiento/PROYECTO/Asis-Track/front_asis_track/lib'

# Regex to find `padding: ...EdgeInsets... ,` inside `styleFrom(` 
# We need to be careful. The padding is usually on its own line: `padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),`
pattern = re.compile(r'^[ \t]*padding:\s*(?:const\s*)?EdgeInsets\.symmetric\([^)]+\),?\s*\n', re.MULTILINE)

for root, _, files in os.walk(lib_dir):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            new_content = pattern.sub('', content)
            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                print(f"Updated {path}")
