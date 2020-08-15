project(
    'spotlight',
    'vala', 'c',
    version: '0.0.2',
    meson_version: '>=0.45.0'
)

PROJECT_NAME = 'spotlight'
prefix = get_option('prefix')
libdir = join_paths(prefix, get_option('libdir'))
datadir = join_paths(prefix, get_option('datadir'))

VAPI_DIR = join_paths(meson.source_root(), 'vapi')
vala = meson.get_compiler('vala')

conf = configuration_data()
conf.set_quoted('PROJECT_NAME', PROJECT_NAME)
conf.set_quoted('PACKAGE_LIBDIR', libdir)
conf.set_quoted('PACKAGE_SHAREDIR', datadir)

config_h = configure_file(
	output: 'config.h',
	configuration: conf
)

config_dep = declare_dependency(
	dependencies: vala.find_library('config', dirs: VAPI_DIR),
	sources: config_h
)

config_inc_dir = include_directories('.')

SpotlightValaArgs = [
    '--pkg=config',
    '--vapidir=' + VAPI_DIR,
    '--target-glib=2.38',
]

# Calculator Widget
add_global_arguments('-DGETTEXT_PACKAGE=@0@'.format(meson.project_name()), language:'c')

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),
    'src/Application.vala',
    'src/DesktopEntries.vala',
    'src/Widgets/Calculator/Core/Evaluation.vala',
    'src/Widgets/Calculator/Core/Scanner.vala',
    'src/Widgets/Calculator/Core/Token.vala',
    dependencies: [
        dependency('gio-unix-2.0', version: '>=2.56.0'),
        dependency('glib-2.0', version: '>=2.56.0'),
        dependency('gtk+-3.0', version: '>=3.22'),
        dependency('gdk-3.0', version: '>=3.22.0'),
        dependency('cairo', version: '>=1.15.0'),
        dependency('pango', version: '>=1.40.0'),
        dependency('libgnome-menu-3.0', version: '>=3.13.0'),
		dependency('gee-0.8', version: '>=0.20.0'),
		meson.get_compiler('vala').find_library('posix'),
        # Similar to add options "-X -lm" in cmake to use Math.pow()
        meson.get_compiler('c').find_library('m', required: false)
    ],
    c_args: [
        '-DGMENU_I_KNOW_THIS_IS_UNSTABLE',
    ],
    vala_args: SpotlightValaArgs,
    include_directories: config_inc_dir,
    install: true
)

# Install CSS file
install_data(
    join_paths('data', 'spotlight.css'),
    install_dir: join_paths(datadir, PROJECT_NAME)
)
