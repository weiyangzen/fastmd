#!/usr/bin/env ruby

require 'fileutils'
require 'pathname'
require 'xcodeproj'

REPO_ROOT = Pathname(__dir__).join('..').expand_path
MACOS_ROOT = REPO_ROOT.join('apps/macos')
PROJECT_PATH = MACOS_ROOT.join('FastMD.xcodeproj')
APP_NAME = 'FastMD'
TEST_NAME = 'FastMDTests'
MACOS_DEPLOYMENT_TARGET = '14.0'
APP_BUNDLE_ID = 'com.wangweiyang.FastMD'
TEST_BUNDLE_ID = 'com.wangweiyang.FastMDTests'
MACOS_APP_SOURCE_DIR = 'Sources/FastMD'
MACOS_APP_RESOURCE_DIR = 'Sources/FastMD/Resources'
MACOS_TEST_DIR = 'Tests/FastMDTests'

def swift_files(in_relative_dir)
  MACOS_ROOT.join(in_relative_dir)
      .children
      .select { |path| path.extname == '.swift' }
      .sort_by(&:to_s)
end

def resource_files(in_relative_dir)
  Dir.glob(MACOS_ROOT.join(in_relative_dir, '**', '*').to_s)
     .map { |path| Pathname(path) }
     .select(&:file?)
     .sort_by(&:to_s)
end

def configure_project(project)
  project.root_object.attributes['LastUpgradeCheck'] = '2640'
  project.root_object.attributes['LastSwiftUpdateCheck'] = '2640'
  project.root_object.attributes['ORGANIZATIONNAME'] = 'wangweiyang'

  project.build_configurations.each do |config|
    config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = MACOS_DEPLOYMENT_TARGET
    config.build_settings['SDKROOT'] = 'macosx'
    config.build_settings['SWIFT_VERSION'] = '6.0'
  end
end

def configure_app_target(target)
  target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_IDENTITY'] = ''
    config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
    config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
    config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    config.build_settings['INFOPLIST_KEY_LSApplicationCategoryType'] = 'public.app-category.productivity'
    config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = APP_NAME
    config.build_settings['INFOPLIST_KEY_LSUIElement'] = 'YES'
    config.build_settings['INFOPLIST_KEY_NSAppleEventsUsageDescription'] = 'FastMD needs Finder automation to resolve hovered Markdown file paths.'
    config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = MACOS_DEPLOYMENT_TARGET
    config.build_settings['MARKETING_VERSION'] = '0.0.7'
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = APP_BUNDLE_ID
    config.build_settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
    config.build_settings['SDKROOT'] = 'macosx'
    config.build_settings['SWIFT_EMIT_LOC_STRINGS'] = 'NO'
    config.build_settings['SWIFT_VERSION'] = '6.0'
  end
end

def configure_test_target(target)
  target.build_configurations.each do |config|
    config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
    config.build_settings['CODE_SIGN_IDENTITY'] = ''
    config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
    config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = MACOS_DEPLOYMENT_TARGET
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = TEST_BUNDLE_ID
    config.build_settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
    config.build_settings['SDKROOT'] = 'macosx'
    config.build_settings['SWIFT_VERSION'] = '6.0'
    config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/FastMD.app/Contents/MacOS/FastMD'
  end
end

def new_group(parent, name, path)
  group = parent.new_group(name, path)
  group.set_path(path)
  group
end

def add_files_to_target(group, target, files)
  references = files.map { |path| group.new_file(path.basename.to_s) }
  target.add_file_references(references)
end

def add_resource_files_to_target(group, target, files, relative_root)
  references = files.map do |path|
    relative_path = path.relative_path_from(MACOS_ROOT.join(relative_root)).to_s
    group.new_file(relative_path)
  end

  references.each do |reference|
    target.resources_build_phase.add_file_reference(reference, true)
  end
end

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH.to_s)
configure_project(project)

sources_group = new_group(project.main_group, 'Sources', 'Sources')
app_group = new_group(sources_group, APP_NAME, APP_NAME)
resources_group = new_group(app_group, 'Resources', 'Resources')
tests_group = new_group(project.main_group, 'Tests', 'Tests')
test_group = new_group(tests_group, TEST_NAME, TEST_NAME)

app_target = project.new_target(:application, APP_NAME, :osx, MACOS_DEPLOYMENT_TARGET)
test_target = project.new_target(:unit_test_bundle, TEST_NAME, :osx, MACOS_DEPLOYMENT_TARGET)
test_target.add_dependency(app_target)

project.files.each do |file|
  next unless file.path&.end_with?('Cocoa.framework')
  file.path = 'System/Library/Frameworks/Cocoa.framework'
  file.source_tree = 'SDKROOT'
end

configure_app_target(app_target)
configure_test_target(test_target)

add_files_to_target(app_group, app_target, swift_files(MACOS_APP_SOURCE_DIR))
add_resource_files_to_target(resources_group, app_target, resource_files(MACOS_APP_RESOURCE_DIR), MACOS_APP_RESOURCE_DIR)
add_files_to_target(test_group, test_target, swift_files(MACOS_TEST_DIR))

project.main_group.sort_recursively_by_type
project.save

scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(app_target, test_target, launch_target: true)
scheme.save_as(PROJECT_PATH, APP_NAME, true)

puts "Generated #{PROJECT_PATH.relative_path_from(REPO_ROOT)}"
