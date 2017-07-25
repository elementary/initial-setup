project('io.elementary.initial-setup', 'vala', 'c')

add_global_arguments('-DGETTEXT_PACKAGE="io.elementary.initial-setup"', language:'c')

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/MainWindow.vala',
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gtk+-3.0')
    ],
    install : true
)
