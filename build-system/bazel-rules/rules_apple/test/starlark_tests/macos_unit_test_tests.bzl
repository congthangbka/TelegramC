# Copyright 2019 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""macos_unit_test Starlark tests."""

load(
    ":common.bzl",
    "common",
)
load(
    "//test/starlark_tests/rules:analysis_failure_message_test.bzl",
    "analysis_failure_message_test",
)
load(
    "//test/starlark_tests/rules:apple_verification_test.bzl",
    "apple_verification_test",
)
load(
    "//test/starlark_tests/rules:common_verification_tests.bzl",
    "archive_contents_test",
)
load(
    "//test/starlark_tests/rules:dsyms_test.bzl",
    "dsyms_test",
)
load(
    "//test/starlark_tests/rules:infoplist_contents_test.bzl",
    "infoplist_contents_test",
)
load(
    "//test/starlark_tests/rules:analysis_runfiles_test.bzl",
    "analysis_runfiles_test",
)

def macos_unit_test_test_suite(name):
    """Test suite for macos_unit_test.

    Args:
      name: the base name to be used in things created by this macro
    """
    apple_verification_test(
        name = "{}_codesign_test".format(name),
        build_type = "device",
        target_under_test = "//test/starlark_tests/targets_under_test/macos:unit_test",
        verifier_script = "verifier_scripts/codesign_verifier.sh",
        tags = [name],
    )

    archive_contents_test(
        name = "{}_additional_contents_test".format(name),
        build_type = "device",
        contains = [
            "$CONTENT_ROOT/Additional/additional.txt",
            "$CONTENT_ROOT/Nested/non_nested.txt",
            "$CONTENT_ROOT/Nested/nested/nested.txt",
        ],
        plist_test_file = "$CONTENT_ROOT/Info.plist",
        plist_test_values = {
            "BuildMachineOSBuild": "*",
            "CFBundleExecutable": "unit_test",
            "CFBundleIdentifier": "com.google.exampleTests",
            "CFBundleName": "unit_test",
            "CFBundlePackageType": "BNDL",
            "CFBundleSupportedPlatforms:0": "MacOSX",
            "DTCompiler": "com.apple.compilers.llvm.clang.1_0",
            "DTPlatformBuild": "*",
            "DTPlatformName": "macosx",
            "DTPlatformVersion": "*",
            "DTSDKBuild": "*",
            "DTSDKName": "macosx*",
            "DTXcode": "*",
            "DTXcodeBuild": "*",
            "LSMinimumSystemVersion": common.min_os_macos.baseline,
        },
        target_under_test = "//test/starlark_tests/targets_under_test/macos:unit_test",
        tags = [name],
    )

    dsyms_test(
        name = "{}_dsyms_test".format(name),
        target_under_test = "//test/starlark_tests/targets_under_test/macos:unit_test",
        expected_direct_dsyms = ["unit_test.__internal__.__test_bundle_dsyms/unit_test.xctest"],
        expected_transitive_dsyms = ["unit_test.__internal__.__test_bundle_dsyms/unit_test.xctest", "app_dsyms/app.app"],
        tags = [name],
    )

    infoplist_contents_test(
        name = "{}_test_bundle_id_override".format(name),
        target_under_test = "//test/starlark_tests/targets_under_test/macos:unit_test_custom_bundle_id",
        expected_values = {
            "CFBundleIdentifier": "my.test.bundle.id",
        },
        tags = [name],
    )

    analysis_failure_message_test(
        name = "{}_test_bundle_id_same_as_test_host_error".format(name),
        target_under_test = "//test/starlark_tests/targets_under_test/macos:unit_test_invalid_bundle_id",
        expected_error = "The test bundle's identifier of 'com.google.example' can't be the same as the test host's bundle identifier. Please change one of them.",
        tags = [name],
    )

    archive_contents_test(
        name = "{}_builds_without_test_host".format(name),
        build_type = "simulator",
        target_under_test = "//test/starlark_tests/targets_under_test/macos:unit_test_no_host",
        cpus = {
            "macos_cpus": ["x86_64"],
        },
        binary_test_file = "$BINARY",
        binary_test_architecture = "x86_64",
        macho_load_commands_contain = ["cmd LC_BUILD_VERSION", "minos 11.0", "platform MACOS"],
        tags = [name],
    )

    analysis_runfiles_test(
        name = "{}_transitive_runfiles_included".format(name),
        tags = [name],
        target_under_test = "//test/starlark_tests/targets_under_test/macos:unit_test_data_deps",
        expected_runfiles = [
            "test/starlark_tests/targets_under_test/macos/runfile1.txt",
            "test/starlark_tests/targets_under_test/macos/runfile2.txt",
        ],
    )

    native.test_suite(
        name = name,
        tags = [name],
    )