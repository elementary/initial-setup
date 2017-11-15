
vala_files = [
    'Application.vala',
    'MainWindow.vala',
    'Helpers/KeyboardLayoutHelper.vala',
    'Helpers/LocaleHelper.vala',
    'Objects/Configuration.vala',
    'Utils.vala',
    'Views/AbstractInstallerView.vala',
    'Views/KeyboardLayoutView.vala',
    'Views/LanguageView.vala',
    'Widgets/LayoutWidget.vala',
    'Widgets/VariantWidget.vala'
]

configuration_data = configuration_data()
configuration_data.set('GETTEXT_PACKAGE', meson.project_name())
configuration_data.set('LANG_LIST', get_option('supported_languages'))
configuration_data.set('PREFERRED_LANG_LIST', get_option('preferred_languages'))

config_file = configure_file(
    input: 'Config.vala.in',
    output: 'Config.vala',
    configuration: configuration_data
)

executable(meson.project_name(), vala_files, config_file,
           asresources,
           dependencies : dependencies,
           install: true)
