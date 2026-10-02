"""Generate the small dependency-free Xcode project; rerun after adding source files."""
from pathlib import Path
import hashlib
root=Path(__file__).resolve().parent
objects={}
def ident(name): return hashlib.sha256(name.encode()).hexdigest()[:24].upper()
def obj(name,body):
 i=ident(name);objects[i]=body;return i
def ref(path,typ): return obj(path, f'isa = PBXFileReference; lastKnownFileType = {typ}; path = "{path}"; sourceTree = "<group>";')
def listing(ids):return '('+','.join(ids)+',)'
app=ident('app');test=ident('test');project=ident('project')
source=[];refs=[];test_sources=[]
for p in sorted((root/'LetterAssistant').rglob('*.swift')):
 path=str(p.relative_to(root));r=ref(path,'sourcecode.swift');refs.append(r)
 source.append(obj('build:'+path,f'isa = PBXBuildFile; fileRef = {r};'))
for p in sorted((root/'LetterAssistantTests').glob('*.swift')):
 path=str(p.relative_to(root));r=ref(path,'sourcecode.swift');refs.append(r)
 test_sources.append(obj('build:'+path,f'isa = PBXBuildFile; fileRef = {r};'))
resources=[]
for fixture in ['fictional-bill', 'fictional-bill-page2']:
 r=ref(f'../fixtures/letters/{fixture}.jpg','image.jpeg');refs.append(r)
 resources.append(obj('fixture-build:'+fixture,f'isa = PBXBuildFile; fileRef = {r};'))
product=obj('app-product','isa = PBXFileReference; explicitFileType = wrapper.application; path = LetterAssistant.app; sourceTree = BUILT_PRODUCTS_DIR;')
tproduct=obj('test-product','isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = LetterAssistantTests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
products=obj('products',f'isa = PBXGroup; children = {listing([product,tproduct])}; name = Products; sourceTree = "<group>";')
group=obj('main',f'isa = PBXGroup; children = {listing(refs+[products])}; sourceTree = "<group>";')
def phase(name,kind,items):return obj(name,f'isa = {kind}; buildActionMask = 2147483647; files = {listing(items) if items else "()"}; runOnlyForDeploymentPostprocessing = 0;')
a_sources=phase('sources','PBXSourcesBuildPhase',source)
a_res=phase('resources','PBXResourcesBuildPhase',resources)
a_framework=phase('frameworks','PBXFrameworksBuildPhase',[])
t_sources=phase('test-sources','PBXSourcesBuildPhase',test_sources)
t_framework=phase('test-frameworks','PBXFrameworksBuildPhase',[])
script='if [ "$CONFIGURATION" = "Debug" ] && [ -f "$SRCROOT/Config/Debug.local.plist" ]; then\n  cp "$SRCROOT/Config/Debug.local.plist" "$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/Debug.local.plist"\nelse\n  rm -f "$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/Debug.local.plist"\nfi\n'
import json
shell=obj('local-config',f'isa = PBXShellScriptBuildPhase; buildActionMask = 2147483647; files = (); inputPaths = (); outputPaths = (); alwaysOutOfDate = 1; name = "Development connection only"; shellPath = /bin/sh; shellScript = {json.dumps(script)}; runOnlyForDeploymentPostprocessing = 0;')
def configlist(name,settings):
 configs=[]
 for mode in ('Debug','Release'):
  values=settings.copy()
  values['SWIFT_OPTIMIZATION_LEVEL']='-Onone' if mode=='Debug' else '-O'
  values['SWIFT_ACTIVE_COMPILATION_CONDITIONS']='DEBUG' if mode=='Debug' else ''
  if mode=='Debug':values['ENABLE_TESTABILITY']='YES'
  body=' '.join(f'{k} = {json.dumps(v)};' for k,v in values.items())
  configs.append(obj(name+mode,f'isa = XCBuildConfiguration; buildSettings = {{{body}}}; name = {mode};'))
 return obj(name+'configs',f'isa = XCConfigurationList; buildConfigurations = {listing(configs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
common={'SDKROOT':'iphoneos','IPHONEOS_DEPLOYMENT_TARGET':'17.0','SWIFT_VERSION':'5.0','CLANG_ENABLE_MODULES':'YES','CODE_SIGN_STYLE':'Automatic','TARGETED_DEVICE_FAMILY':'1','ENABLE_USER_SCRIPT_SANDBOXING':'NO'}
pconfigs=configlist('project',common)
a_configs=configlist('app',{'PRODUCT_NAME':'$(TARGET_NAME)','PRODUCT_BUNDLE_IDENTIFIER':'com.example.LetterAssistant','INFOPLIST_FILE':'LetterAssistant/Info.plist','GENERATE_INFOPLIST_FILE':'NO','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/Frameworks'})
t_configs=configlist('test',{'PRODUCT_NAME':'$(TARGET_NAME)','PRODUCT_BUNDLE_IDENTIFIER':'com.example.LetterAssistantTests','GENERATE_INFOPLIST_FILE':'YES','TEST_HOST':'$(BUILT_PRODUCTS_DIR)/LetterAssistant.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/LetterAssistant','BUNDLE_LOADER':'$(TEST_HOST)','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/Frameworks @loader_path/Frameworks'})
proxy=obj('proxy',f'isa = PBXContainerItemProxy; containerPortal = {project}; proxyType = 1; remoteGlobalIDString = {app}; remoteInfo = LetterAssistant;')
dep=obj('dependency',f'isa = PBXTargetDependency; target = {app}; targetProxy = {proxy};')
obj('app',f'isa = PBXNativeTarget; buildConfigurationList = {a_configs}; buildPhases = {listing([a_sources,a_framework,a_res,shell])}; buildRules = (); dependencies = (); name = LetterAssistant; productName = LetterAssistant; productReference = {product}; productType = "com.apple.product-type.application";')
obj('test',f'isa = PBXNativeTarget; buildConfigurationList = {t_configs}; buildPhases = {listing([t_sources,t_framework])}; buildRules = (); dependencies = {listing([dep])}; name = LetterAssistantTests; productName = LetterAssistantTests; productReference = {tproduct}; productType = "com.apple.product-type.bundle.unit-test";')
obj('project',f'isa = PBXProject; attributes = {{LastUpgradeCheck = 2600; BuildIndependentTargetsInParallel = YES; }}; buildConfigurationList = {pconfigs}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; knownRegions = (en, Base, "zh-Hans"); mainGroup = {group}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = {listing([app,test])};')
# A focused UI target checks Chinese controls and large Dynamic Type on the simulator.
u_sources=[]
for p in sorted((root/'LetterAssistantUITests').glob('*.swift')):
 path=str(p.relative_to(root));r=ref(path,'sourcecode.swift')
 objects[group]=objects[group].replace(products+',)',r+','+products+',)')
 u_sources.append(obj('build:'+path,f'isa = PBXBuildFile; fileRef = {r};'))
u_product=obj('ui-product','isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = LetterAssistantUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
objects[products]=objects[products].replace(tproduct+',)',tproduct+','+u_product+',)')
u_config=configlist('ui',{'PRODUCT_NAME':'$(TARGET_NAME)','PRODUCT_BUNDLE_IDENTIFIER':'com.example.LetterAssistantUITests','GENERATE_INFOPLIST_FILE':'YES','TEST_TARGET_NAME':'LetterAssistant','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/Frameworks @loader_path/Frameworks'})
u_phase=phase('ui-sources','PBXSourcesBuildPhase',u_sources)
u_framework=phase('ui-frameworks','PBXFrameworksBuildPhase',[])
u_target=obj('ui',f'isa = PBXNativeTarget; buildConfigurationList = {u_config}; buildPhases = {listing([u_phase,u_framework])}; buildRules = (); dependencies = {listing([dep])}; name = LetterAssistantUITests; productName = LetterAssistantUITests; productReference = {u_product}; productType = "com.apple.product-type.bundle.ui-testing";')
objects[project]=objects[project].replace(listing([app,test]),listing([app,test,u_target]))
proj=root/'LetterAssistant.xcodeproj';proj.mkdir(exist_ok=True)
(proj/'project.pbxproj').write_text('// !$*UTF8*$!\n{archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+'\n'.join(f'{k} = {{{v}}};' for k,v in objects.items())+f'\n}}; rootObject = {project};}}\n')
schemes=proj/'xcshareddata/xcschemes';schemes.mkdir(parents=True,exist_ok=True)
def buildref(i,name):return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{i}" BuildableName="{name}" BlueprintName="{name.split(".")[0]}" ReferencedContainer="container:LetterAssistant.xcodeproj"/>'
(schemes/'LetterAssistant.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{buildref(app,'LetterAssistant.app')}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{buildref(test,'LetterAssistantTests.xctest')}</TestableReference><TestableReference skipped="NO">{buildref(u_target,'LetterAssistantUITests.xctest')}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{buildref(app,'LetterAssistant.app')}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{buildref(app,'LetterAssistant.app')}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print('Generated shared Xcode app/test project.')
