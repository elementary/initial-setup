
vala_files = [
    'Application.vala',
    'MainWindow.vala',
    'Helpers/AccountsServiceInterface.vala',
    'Helpers/LocaleHelper.vala',
    'Objects/Configuration.vala',
    'Objects/KeyboardLayout.vala',
    'Objects/KeyboardVariant.vala',
    'Utils.vala',
    'Views/AbstractInstallerView.vala',
    'Views/AccountView.vala',
    'Views/KeyboardLayoutView.vala',
    'Views/LanguageView.vala',
    'Widgets/LayoutWidget.vala',
    'Widgets/VariantWidget.vala'
]

configuration_data = configuration_data()
configuration_data.set('GETTEXT_PACKAGE', meson.project_name())
configuration_data.set('LANG_LIST', get_option('supported_languages'))
configuration_data.set('PREFERRED_LANG_LIST', get_option('preferred_languages'))

xkbconf = dependency('xkeyboard-config')
xkb_base = xkbconf.get_pkgconfig_variable('xkb_base')
configuration_data.set('XKB_BASE', xkb_base)

isocodes = dependency('iso-codes')
isocodes_prefix = isocodes.get_pkgconfig_variable('prefix')
isocodes_location = join_paths(isocodes_prefix, get_option('datadir'), 'iso-codes', 'json')
configuration_data.set('ISO_CODES_LOCATION', isocodes_location)

config_file = configure_file(
    input: 'Config.vala.in',
    output: 'Config.vala',
    configuration: configuration_data
)

executable(meson.project_name(), vala_files, config_file,
           asresources,
           dependencies : dependencies,
           install: true)
