#!/usr/bin/env ruby
# Adds the TVKit shared sources and the TVWidgets extension (widget, Live
# Activity, Control Center controls) to apps/remote/ios/Runner.xcodeproj.
# Idempotent: safe to run on every build. Uses the xcodeproj gem (CocoaPods).
require 'xcodeproj'

ROOT = File.expand_path('../../apps/remote/ios', __dir__)
project = Xcodeproj::Project.open(File.join(ROOT, 'Runner.xcodeproj'))
runner = project.targets.find { |t| t.name == 'Runner' } or abort 'Runner target missing'

IOS_TARGET = '17.0'
BUNDLE = 'com.luiszapata.tvcontrol.tvRemote'
changed = false

def group_for(project, name)
  project.main_group.children.find { |g| g.display_name == name } ||
    project.main_group.new_group(name, name)
end

def ensure_file(group, name)
  group.files.find { |f| f.path == name } || group.new_reference(name)
end

def ensure_in_phase(target, ref)
  return false if target.source_build_phase.files_references.include?(ref)
  target.source_build_phase.add_file_reference(ref)
  true
end

# --- Runner settings
runner.build_configurations.each do |c|
  s = c.build_settings
  if s['IPHONEOS_DEPLOYMENT_TARGET'] != IOS_TARGET
    s['IPHONEOS_DEPLOYMENT_TARGET'] = IOS_TARGET
    changed = true
  end
  if s['CODE_SIGN_ENTITLEMENTS'] != 'Runner/Runner.entitlements'
    s['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
    changed = true
  end
end
project.build_configurations.each do |c|
  if c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] != IOS_TARGET
    c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = IOS_TARGET
    changed = true
  end
end

runner_group = project.main_group.children.find { |g| g.display_name == 'Runner' }
%w[SharedBridge.swift TVShortcuts.swift].each do |f|
  changed |= ensure_in_phase(runner, ensure_file(runner_group, f))
end
ensure_file(runner_group, 'Runner.entitlements')

# --- Extension target
ext = project.targets.find { |t| t.name == 'TVWidgets' }
unless ext
  ext = project.new_target(:app_extension, 'TVWidgets', :ios, IOS_TARGET)
  changed = true
end
ext.build_configurations.each do |c|
  s = c.build_settings
  wanted = {
    'PRODUCT_BUNDLE_IDENTIFIER' => "#{BUNDLE}.TVWidgets",
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'INFOPLIST_FILE' => 'TVWidgets/Info.plist',
    'CODE_SIGN_ENTITLEMENTS' => 'TVWidgets/TVWidgets.entitlements',
    'IPHONEOS_DEPLOYMENT_TARGET' => IOS_TARGET,
    'SWIFT_VERSION' => '5.0',
    'TARGETED_DEVICE_FAMILY' => '1',
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'SKIP_INSTALL' => 'YES',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
  }
  wanted.each do |k, v|
    next if s[k] == v
    s[k] = v
    changed = true
  end
end

# Version strings come from Flutter's Generated.xcconfig (not the Pods one:
# the extension links no plugins).
widgets_group = group_for(project, 'TVWidgets')
xcconfig = ensure_file(widgets_group, 'TVWidgets.xcconfig')
ext.build_configurations.each do |c|
  next if c.base_configuration_reference == xcconfig
  c.base_configuration_reference = xcconfig
  changed = true
end
changed |= ensure_in_phase(ext, ensure_file(widgets_group, 'TVWidgets.swift'))
ensure_file(widgets_group, 'Info.plist')
ensure_file(widgets_group, 'TVWidgets.entitlements')

# Shared sources compiled into both targets.
kit_group = group_for(project, 'TVKit')
Dir.children(File.join(ROOT, 'TVKit')).select { |f| f.end_with?('.swift') }.sort.each do |f|
  ref = ensure_file(kit_group, f)
  changed |= ensure_in_phase(runner, ref)
  changed |= ensure_in_phase(ext, ref)
end

# Embed the extension in the app, before Flutter's "Thin Binary" script
# (otherwise Xcode reports a build cycle).
unless runner.dependencies.any? { |d| d.target == ext }
  runner.add_dependency(ext)
  changed = true
end
embed = runner.copy_files_build_phases.find { |p| p.name == 'Embed Foundation Extensions' }
unless embed
  embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
  embed.symbol_dst_subfolder_spec = :plug_ins
  changed = true
end
unless embed.files_references.include?(ext.product_reference)
  bf = embed.add_file_reference(ext.product_reference)
  bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  changed = true
end
thin = runner.build_phases.find { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
if thin
  phases = runner.build_phases
  if phases.index(embed) > phases.index(thin)
    phases.delete(embed)
    phases.insert(phases.index(thin), embed)
    changed = true
  end
end

if changed
  project.save
  puts 'Runner.xcodeproj updated'
else
  puts 'Runner.xcodeproj already up to date'
end
