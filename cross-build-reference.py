import pathlib,subprocess,concurrent.futures,json,time
root=pathlib.Path('/home/user/xsgps-updated');out=pathlib.Path('/home/user/xsgps-compile/final');out.mkdir(exist_ok=True)
sdk='/home/user/ios-sdk-check/iPhoneOS16.5.sdk'
def run(p):
 cmd=['clang','-target','arm64-apple-ios15.0','-isysroot',sdk,'-fobjc-arc','-fblocks','-Os','-DXSGPS_LOCAL_TEST=1','-I'+str(root),'-Wno-deprecated-declarations','-Wno-nullability-completeness','-c',str(p),'-o',str(out/(p.stem+'.o'))]
 r=subprocess.run(cmd,capture_output=True,text=True);(out/(p.stem+'.log')).write_text(r.stdout+r.stderr);return {'source':p.name,'exit_code':r.returncode,'command':cmd}
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as e: results=list(e.map(run,[p for p in root.glob('*.m') if p.name!='LocationSpoofer.m']))
report={'mode':'Linux Clang 19 ARM64 iOS cross-compilation; NOT macOS Xcode/Theos execution or device runtime','sources':results}
if any(r['exit_code'] for r in results):
 (out/'verification.json').write_text(json.dumps(report,indent=2));print('FAILED',[r['source'] for r in results if r['exit_code']]);raise SystemExit(1)
frameworks=['Foundation','UIKit','CoreLocation','MapKit','Photos','PhotosUI','CoreBluetooth','AVFoundation','CoreMedia','Security','WebKit','SystemConfiguration','CoreGraphics','QuartzCore']
cmd=['/usr/bin/ld64.lld-19','-dylib','-arch','arm64','-platform_version','ios','15.0','16.5','-syslibroot',sdk,'-adhoc_codesign','-install_name','@executable_path/Frameworks/XsGpS.dylib','-o',str(out/'XsGpS.dylib')]+[str(p) for p in out.glob('*.o')]
for f in frameworks:cmd+=['-framework',f]
cmd+=['-lSystem','-lobjc']
r=subprocess.run(cmd,capture_output=True,text=True);(out/'link.log').write_text(r.stdout+r.stderr);report['link']={'exit_code':r.returncode,'command':cmd};(out/'verification.json').write_text(json.dumps(report,indent=2));print('Compiled',len(results),'sources; linked:',r.returncode==0)
raise SystemExit(r.returncode)
