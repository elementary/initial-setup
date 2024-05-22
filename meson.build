project(
  'io.elementary.initial-setup',
  'vala', 'c',
  version: '6.3.0',
)

add_global_arguments('-DGETTEXT_PACKAGE="' + meson.project_name() + '"', language:'c')
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
                      language: 'vala')

gnome = import('gnome')
i18n = import('i18n')

accountservice_dep = dependency('accountsservice')
gee_dep = dependency('gee-0.8')
glib_dep = dependency('glib-2.0', version: '>=2.74')
gobject_dep = dependency('gobject-2.0')
granite_dep = dependency('granite-7', version: '>=7.4.0')
gtk_dep = dependency('gtk4')
adw_dep = dependency('libadwaita-1', version: '>=1.4.0')
json_glib_dep = dependency('json-glib-1.0')
polkit_dep = dependency('polkit-gobject-1')
posix_dep = meson.get_compiler('vala').find_library('posix')
pwquality_dep = dependency('pwquality')
xml2_dep = dependency('libxml-2.0')

dependencies = [
    accountservice_dep,
    gee_dep,
    glib_dep,
    gobject_dep,
    granite_dep,
    gtk_dep,
    adw_dep,
    json_glib_dep,
    polkit_dep,
    posix_dep,
    pwquality_dep,
    xml2_dep,
]

subdir('po')
subdir('src')
subdir('data')
