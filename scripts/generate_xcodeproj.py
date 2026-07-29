#!/usr/bin/env python3
"""Generate AussieStart.xcodeproj from the on-disk source tree."""
from __future__ import annotations

import uuid
from pathlib import Path

ROOT = Path("/Users/harpreetsingh/Desktop/AussieStart")
APP = ROOT / "AussieStart"


def uid() -> str:
    return uuid.uuid4().hex[:24].upper()


def file_type(path: Path) -> str:
    if path.suffix == ".swift":
        return "sourcecode.swift"
    if path.suffix == ".json":
        return "text.json"
    if path.suffix == ".md":
        return "net.daringfireball.markdown"
    if path.suffix == ".plist":
        return "text.plist.xml"
    if path.suffix == ".strings":
        return "text.plist.strings"
    if path.suffix == ".xcprivacy":
        return "text.xml"
    if path.name.endswith(".xcassets"):
        return "folder.assetcatalog"
    return "text"


class Project:
    def __init__(self):
        self.objects: dict[str, str] = {}

    def add(self, oid: str, body: str) -> str:
        self.objects[oid] = body
        return oid


def main() -> None:
    p = Project()

    app_product = uid()
    app_target = uid()
    root_group = uid()
    products_group = uid()
    app_group = uid()
    project_id = uid()

    sources_phase = uid()
    resources_phase = uid()
    frameworks_phase = uid()

    project_configs = uid()
    app_configs = uid()
    proj_debug, proj_release = uid(), uid()
    app_debug, app_release = uid(), uid()

    file_refs: dict[str, tuple[str, Path]] = {}

    def ensure_ref(path: Path) -> str:
        key = str(path.relative_to(ROOT))
        if key not in file_refs:
            file_refs[key] = (uid(), path)
        return file_refs[key][0]

    swifts = sorted(APP.rglob("*.swift"))
    resource_paths: list[Path] = [
        APP / "Assets.xcassets",
        APP / "PrivacyInfo.xcprivacy",
        APP / "Resources" / "Content" / "catalog.json",
    ]
    resource_paths += sorted((APP / "Resources" / "Content" / "articles").glob("*.md"))
    resource_paths += sorted((APP / "Resources" / "Localization").rglob("*.strings"))

    extras = [APP / "Info.plist"]

    for path in swifts + resource_paths + extras:
        ensure_ref(path)

    source_bfs: list[tuple[str, str]] = []
    for path in swifts:
        bid = uid()
        ref = ensure_ref(path)
        p.add(bid, f"{bid} /* {path.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {path.name} */; }};")
        source_bfs.append((bid, path.name))

    resource_bfs: list[tuple[str, str]] = []
    for path in resource_paths:
        bid = uid()
        ref = ensure_ref(path)
        p.add(bid, f"{bid} /* {path.name} in Resources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {path.name} */; }};")
        resource_bfs.append((bid, path.name))

    p.add(
        app_product,
        f"{app_product} /* AussieStart.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = AussieStart.app; sourceTree = BUILT_PRODUCTS_DIR; }};",
    )

    for _, (ref, path) in file_refs.items():
        # Quote paths with spaces / special chars
        path_value = path.name
        if any(c in path_value for c in [" ", "+", "-"]) or path_value.endswith(".xcassets"):
            path_literal = f'path = "{path_value}";'
        else:
            path_literal = f"path = {path_value};"
        p.add(
            ref,
            f'{ref} /* {path.name} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type(path)}; {path_literal} sourceTree = "<group>"; }};',
        )

    group_ids: dict[str, str] = {}

    def make_group(name: str, path_name: str | None, child_ids: list[str]) -> str:
        gid = uid()
        children = ",\n".join(f"\t\t\t\t{c}" for c in child_ids)
        path_line = f"\n\t\t\tpath = {path_name};" if path_name else ""
        name_line = f"\n\t\t\tname = {name};" if not path_name else ""
        p.add(
            gid,
            f"{gid} /* {name} */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n{children}\n\t\t\t);{name_line}{path_line}\n\t\t\tsourceTree = \"<group>\";\n\t\t}};",
        )
        group_ids[name] = gid
        return gid

    def refs_for_files(files: list[Path]) -> list[str]:
        out = []
        for path in files:
            key = str(path.relative_to(ROOT))
            if key in file_refs:
                out.append(file_refs[key][0])
        return out

    def build_dir_group(dir_path: Path, relative_root: Path = APP) -> str:
        """Recursively build groups mirroring folders."""
        child_ids: list[str] = []
        for child in sorted([p for p in dir_path.iterdir() if p.is_dir() and not p.name.startswith(".")], key=lambda p: p.name):
            if child.suffix == ".xcassets":
                key = str(child.relative_to(ROOT))
                if key in file_refs:
                    child_ids.append(file_refs[key][0])
                continue
            if child.name.endswith(".lproj"):
                # Localization variant folder
                lproj_children = refs_for_files(sorted([p for p in child.iterdir() if p.is_file()], key=lambda p: p.name))
                child_ids.append(make_group(child.name, child.name, lproj_children))
                continue
            child_ids.append(build_dir_group(child, relative_root))
        files = sorted([p for p in dir_path.iterdir() if p.is_file()], key=lambda p: p.name)
        child_ids.extend(refs_for_files(files))
        for child in sorted(dir_path.glob("*.xcassets"), key=lambda p: p.name):
            key = str(child.relative_to(ROOT))
            if key in file_refs and file_refs[key][0] not in child_ids:
                child_ids.append(file_refs[key][0])
        return make_group(dir_path.name, dir_path.name, child_ids)

    # Build nested groups under AussieStart/
    top_children: list[str] = []
    for child in sorted([p for p in APP.iterdir() if not p.name.startswith(".")], key=lambda p: (not p.is_dir(), p.name)):
        if child.is_dir() and (child.suffix == ".xcassets" or child.name.endswith(".lproj")):
            key = str(child.relative_to(ROOT))
            if key in file_refs:
                top_children.append(file_refs[key][0])
        elif child.is_dir():
            top_children.append(build_dir_group(child))
        else:
            key = str(child.relative_to(ROOT))
            if key in file_refs:
                top_children.append(file_refs[key][0])

    children = ",\n".join(f"\t\t\t\t{c}" for c in top_children)
    p.add(
        app_group,
        f"{app_group} /* AussieStart */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n{children}\n\t\t\t);\n\t\t\tpath = AussieStart;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};",
    )

    p.add(
        products_group,
        f"{products_group} /* Products */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{app_product} /* AussieStart.app */,\n\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};",
    )
    p.add(
        root_group,
        f"{root_group} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{app_group} /* AussieStart */,\n\t\t\t\t{products_group} /* Products */,\n\t\t\t);\n\t\t\tsourceTree = \"<group>\";\n\t\t}};",
    )

    src_children = ",\n".join(f"\t\t\t\t{bid} /* {name} in Sources */" for bid, name in source_bfs)
    p.add(
        sources_phase,
        f"{sources_phase} /* Sources */ = {{\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n{src_children}\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};",
    )
    res_children = ",\n".join(f"\t\t\t\t{bid} /* {name} in Resources */" for bid, name in resource_bfs)
    p.add(
        resources_phase,
        f"{resources_phase} /* Resources */ = {{\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n{res_children}\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};",
    )
    p.add(
        frameworks_phase,
        f"{frameworks_phase} /* Frameworks */ = {{\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};",
    )

    p.add(
        app_target,
        f"""{app_target} /* AussieStart */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {app_configs} /* Build configuration list for PBXNativeTarget "AussieStart" */;
			buildPhases = (
				{sources_phase} /* Sources */,
				{frameworks_phase} /* Frameworks */,
				{resources_phase} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = AussieStart;
			productName = AussieStart;
			productReference = {app_product} /* AussieStart.app */;
			productType = "com.apple.product-type.application";
		}};""",
    )

    project_common = """
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_VERSION = 5.0;
"""
    p.add(
        proj_debug,
        f"""{proj_debug} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{project_common}
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};""",
    )
    p.add(
        proj_release,
        f"""{proj_release} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_VERSION = 5.0;
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};""",
    )

    app_settings = """
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = AussieStart/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = AussieStart;
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.reference";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.aussiestart.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = targeted;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
"""
    p.add(
        app_debug,
        f"{app_debug} /* Debug */ = {{\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {{{app_settings}\t\t\t}};\n\t\t\tname = Debug;\n\t\t}};",
    )
    p.add(
        app_release,
        f"{app_release} /* Release */ = {{\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {{{app_settings}\t\t\t}};\n\t\t\tname = Release;\n\t\t}};",
    )

    p.add(
        project_configs,
        f'{project_configs} /* Build configuration list for PBXProject "AussieStart" */ = {{\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n\t\t\t\t{proj_debug} /* Debug */,\n\t\t\t\t{proj_release} /* Release */,\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t}};',
    )
    p.add(
        app_configs,
        f'{app_configs} /* Build configuration list for PBXNativeTarget "AussieStart" */ = {{\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n\t\t\t\t{app_debug} /* Debug */,\n\t\t\t\t{app_release} /* Release */,\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t}};',
    )

    p.add(
        project_id,
        f"""{project_id} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1600;
				LastUpgradeCheck = 1600;
				TargetAttributes = {{
					{app_target} = {{
						CreatedOnToolsVersion = 16.0;
					}};
				}};
			}};
			buildConfigurationList = {project_configs} /* Build configuration list for PBXProject "AussieStart" */;
			compatibilityVersion = "Xcode 15.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
				hi,
				pa,
			);
			mainGroup = {root_group};
			productRefGroup = {products_group} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{app_target} /* AussieStart */,
			);
		}};""",
    )

    sections = {
        "PBXBuildFile": [],
        "PBXFileReference": [],
        "PBXFrameworksBuildPhase": [],
        "PBXGroup": [],
        "PBXNativeTarget": [],
        "PBXProject": [],
        "PBXResourcesBuildPhase": [],
        "PBXSourcesBuildPhase": [],
        "XCBuildConfiguration": [],
        "XCConfigurationList": [],
    }

    for body in p.objects.values():
        if "isa = PBXBuildFile" in body:
            sections["PBXBuildFile"].append(body)
        elif "isa = PBXFileReference" in body:
            sections["PBXFileReference"].append(body)
        elif "isa = PBXGroup" in body:
            sections["PBXGroup"].append(body)
        elif "isa = PBXSourcesBuildPhase" in body:
            sections["PBXSourcesBuildPhase"].append(body)
        elif "isa = PBXResourcesBuildPhase" in body:
            sections["PBXResourcesBuildPhase"].append(body)
        elif "isa = PBXFrameworksBuildPhase" in body:
            sections["PBXFrameworksBuildPhase"].append(body)
        elif "isa = PBXNativeTarget" in body:
            sections["PBXNativeTarget"].append(body)
        elif "isa = PBXProject" in body:
            sections["PBXProject"].append(body)
        elif "isa = XCBuildConfiguration" in body:
            sections["XCBuildConfiguration"].append(body)
        elif "isa = XCConfigurationList" in body:
            sections["XCConfigurationList"].append(body)
        else:
            raise SystemExit(f"Unknown object:\n{body[:200]}")

    out = [
        "// !$*UTF8*$!",
        "{",
        "\tarchiveVersion = 1;",
        "\tclasses = {};",
        "\tobjectVersion = 56;",
        "\tobjects = {",
        "",
    ]
    for name, items in sections.items():
        out.append(f"/* Begin {name} section */")
        for item in items:
            for line in item.splitlines():
                out.append("\t\t" + line)
        out.append(f"/* End {name} section */")
        out.append("")
    out += [
        "\t};",
        f"\trootObject = {project_id} /* Project object */;",
        "}",
        "",
    ]

    proj_dir = ROOT / "AussieStart.xcodeproj"
    proj_dir.mkdir(exist_ok=True)
    (proj_dir / "project.pbxproj").write_text("\n".join(out))

    scheme_dir = proj_dir / "xcshareddata" / "xcschemes"
    scheme_dir.mkdir(parents=True, exist_ok=True)
    (scheme_dir / "AussieStart.xcscheme").write_text(
        f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{app_target}"
               BuildableName = "AussieStart.app"
               BlueprintName = "AussieStart"
               ReferencedContainer = "container:AussieStart.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target}"
            BuildableName = "AussieStart.app"
            BlueprintName = "AussieStart"
            ReferencedContainer = "container:AussieStart.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
</Scheme>
"""
    )
    print(f"Wrote {proj_dir}/project.pbxproj")
    print(f"Sources: {len(source_bfs)}, Resources: {len(resource_bfs)}")


if __name__ == "__main__":
    main()
