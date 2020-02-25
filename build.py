import argparse
import subprocess
from colorama import Fore, Style
from pathlib import Path
import shutil
import os
import itertools

# python3 build.py --define-on vr

orig_path = Path.cwd()
project_path = Path(os.path.dirname(os.path.realpath(__file__)))
os.chdir(project_path)

project_name = 'net_game'
build_dir = 'build'
src_dir = 'src'
cfg_dir = 'cfg'
assets_dir = 'assets'
libs_dir = 'libs'

bins_all = {'server', 'client'}

build_path = project_path / build_dir
src_path = project_path / src_dir
cfg_path = project_path / cfg_dir
libs_path = project_path / libs_dir
assets_path = project_path / assets_dir

defines_all = {'release'}

indent = "  "

platforms = ['linux', 'windows']
architectures = ['64']


def platformFlags(platform):
    return {
        'windows': ['--tlsEmulation:off', '-d:mingw']
    }.get(platform, [])


def architectureFlags(architecture):
    return {}.get(architecture, [])


def binExtension(platform):
    return {
        'windows': '.exe'
    }.get(platform, '')


def definesToFlags(defines):
    return [f"-d:{x}" for x in defines]


def buildBin(bin, platform, architecture, defines):
    print(
        f"{Fore.YELLOW}{Style.BRIGHT}Building {Fore.BLUE}bin{Style.RESET_ALL} "
        f"for {Fore.MAGENTA}{platform} {architecture}{Fore.RESET}",
        end=''
    )

    bin_filename = f"{project_name}-{bin}-{platform}-{architecture}"

    if len(defines) == 0:
        print()
    else:
        defines_str = ', '.join(defines)
        print(f", {Fore.CYAN}{defines_str}{Fore.RESET}")
        bin_filename += '-' + '-'.join(defines)

    bin_filename += f"{binExtension(platform)}"

    flags = \
        platformFlags(platform) + \
        architectureFlags(architecture) + \
        definesToFlags(defines) + \
        [f"-o:{build_dir}/{bin_filename}"]

    flags_str = " ".join(flags)

    cmd = f"nimble compile {flags_str} {src_dir}/{bin}"
    print(f"{Fore.YELLOW}{Style.BRIGHT}Command{Style.RESET_ALL} {cmd}")
    subprocess.run(cmd, shell=True)


def buildBinsWithDefines(
    bins,
    platform,
    architecture,
    defines_on,
    defines_both
):
    for b in bins:
        for r in range(len(defines_both) + 1):
            for p in itertools.combinations(defines_both, r):
                buildBin(b, platform, architecture, defines_on | set(p))


def buildBins(args):
    if args.defines_on is not None:
        defines_on = set(args.defines_on.split(","))
    else:
        defines_on = set()

    if args.defines_off is not None:
        defines_off = set(args.defines_off.split(","))
    else:
        defines_off = set()

    if args.bins is not None:
        bins = set(args.bins.split(","))
    else:
        bins = bins_all

    defines_both = defines_all
    defines_both -= defines_on
    defines_both -= defines_off

    if args.platform is None:
        if args.architecture is None:
            # Build all
            for p in platforms:
                for a in architectures:
                    buildBinsWithDefines(
                        bins,
                        p,
                        a,
                        defines_on,
                        defines_both
                    )
        else:
            # Build all platforms
            for p in platforms:
                buildBinsWithDefines(
                    bins,
                    p,
                    args.architecture,
                    defines_on,
                    defines_both
                )
    else:
        if args.architecture is None:
            # Build all architectures
            for a in architectures:
                buildBinsWithDefines(
                    bins,
                    args.platform,
                    a,
                    defines_on,
                    defines_both
                )
        else:
            # Build one specific platform and architecture
            buildBinsWithDefines(
                bins,
                args.platform,
                args.architecture,
                defines_on,
                defines_both
            )


def buildCfg(args):
    print(
        f"{Fore.YELLOW}{Style.BRIGHT}Building {Fore.BLUE}cfg{Style.RESET_ALL}"
    )

    build_cfg_path = build_path / cfg_dir

    if build_cfg_path.is_dir() and not args.force_cfg:
        print(f"{indent}Build cfg dir already exists, not replacing")
    else:
        # Build cfg (replace if necessary)

        if build_cfg_path.is_dir():
            print(
                f"{indent}Build cfg already exists, "
                f"{Fore.YELLOW}replacing{Fore.RESET}"
            )
            shutil.rmtree(build_cfg_path)

        shutil.copytree(
            cfg_path,
            build_cfg_path
        )


def buildAssets(args):
    print(
        f"{Fore.YELLOW}{Style.BRIGHT}Building "
        f"{Fore.BLUE}assets{Style.RESET_ALL}"
    )

    build_assets_path = build_path / assets_dir

    if build_assets_path.is_dir() and not args.force_assets:
        print(f"{indent}Build assets dir already exists, not replacing")
    else:
        # Build assets (replace if necessary)

        if build_assets_path.is_dir():
            print(
                f"{indent}Build assets already exists, "
                f"{Fore.YELLOW}replacing{Fore.RESET}"
            )
            shutil.rmtree(build_assets_path)

        shutil.copytree(
            assets_path,
            build_assets_path
        )


def buildLibs(args):
    print(
        f"{Fore.YELLOW}{Style.BRIGHT}Building {Fore.BLUE}libs{Style.RESET_ALL}"
    )

    lib_files = os.listdir(libs_path)
    for lib_file in lib_files:
        lib_filepath = libs_path / lib_file
        build_lib_filepath = build_path / lib_file
        if lib_filepath.is_file() and not build_lib_filepath.is_file():
            print(f"{indent}Copying {Fore.MAGENTA}{lib_file}{Fore.RESET}")
            shutil.copy(lib_filepath, build_path)
        else:
            print(
                f"{indent}{Fore.MAGENTA}{lib_file}{Fore.RESET} "
                f"already exists, not replacing"
            )


def buildAll(args):
    buildCfg(args)
    buildAssets(args)
    buildLibs(args)
    buildBins(args)


parser = argparse.ArgumentParser(description='Build script')

parser.add_argument(
    '-p', '--platform',
    choices=platforms
)

parser.add_argument(
    '-a', '--architecture',
    choices=architectures
)

parser.add_argument(
    '-don', '--defines_on',
    help="""\
Build with only the specified defines on.
Separate defines with commas."""
)

parser.add_argument(
    '-doff', '--defines_off',
    help="""\
Build with only the specified defines off.
Separate defines with commas."""
)

parser.add_argument(
    '-fc', '--force_cfg',
    action='store_const',
    const=1, default=0,
    help='Replace cfg if it exists'
)

parser.add_argument(
    '-fa', '--force_assets',
    action='store_const',
    const=1, default=1,
    help='Replace assets if they exist'
)

parser.add_argument(
    'target',
    default='all',
    choices=['all', 'bins', 'cfg', 'assets', 'libs']
)

parser.add_argument(
    '-b', '--bins',
    help="""\
Build the specified binaries.
Separate names with commas."""
)

args = parser.parse_args()

build_path.mkdir(exist_ok=True)

{
    'all': buildAll,
    'bins': buildBins,
    'cfg': buildCfg,
    'assets': buildAssets,
    'libs': buildLibs
}[args.target](args)

os.chdir(orig_path)
