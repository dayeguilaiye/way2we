"""Run the native T01 flow and capture OS screenshots at explicit test markers."""
import os
import re
import subprocess
import sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
device=sys.argv[1]
android=device.startswith('emulator-')
platform='android' if android else 'ios'
api='http://10.0.2.2:8080' if android else 'http://127.0.0.1:8080'
mail='http://10.0.2.2:8025' if android else 'http://127.0.0.1:8025'
output=root/'.impeccable/review/t01';output.mkdir(parents=True,exist_ok=True)
logs=root/'.artifacts/t01';logs.mkdir(parents=True,exist_ok=True)
cmd=[str(root/'tools/flutter.sh'),'test','integration_test/account_test.dart','-d',device,'--reporter=expanded',f'--dart-define=API_BASE_URL={api}',f'--dart-define=MAILPIT_URL={mail}']
env=dict(os.environ)
if android:env['JAVA_HOME']='/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home'
with (logs/f'account-{platform}.log').open('w') as log:
    process=subprocess.Popen(cmd,cwd=root/'apps/mobile',env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,bufsize=1)
    for line in process.stdout:
        log.write(line);log.flush();print(line,end='',flush=True)
        match=re.search(r'T01_CAPTURE:([\w-]+)',line)
        if match:
            path=output/f'{platform}-{match.group(1)}.png'
            if android:
                with path.open('wb') as image:subprocess.run([str(Path.home()/'Library/Android/sdk/platform-tools/adb'),'-s',device,'exec-out','screencap','-p'],stdout=image,check=True)
            else:subprocess.run(['xcrun','simctl','io',device,'screenshot',str(path)],check=True)
    sys.exit(process.wait())
