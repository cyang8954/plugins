// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:git/git.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'version_check_command.dart';

import 'common.dart';

const String _kBaseSha = 'base_sha';

/// A command to tag the release.
///
/// The tag syntax of a package is <package-name>-v<version>
class TagReleaseCommand extends PluginCommand {
  /// Constructor of the command.
  TagReleaseCommand(
    Directory packagesDir,
    FileSystem fileSystem, {
    ProcessRunner processRunner = const ProcessRunner(),
    this.gitDir,
  }) : super(packagesDir, fileSystem, processRunner: processRunner) {
    argParser.addOption(_kBaseSha);
  }

  /// The git directory to use. By default it uses the parent directory.
  ///
  /// This can be mocked for testing.
  final GitDir gitDir;

  @override
  final String name = 'tag';

  @override
  final String description =
      'Add release tag to the current git ref based on the version in pubspec.';

  @override
  Future<Null> run() async {
    checkSharding();

    final String rootDir = packagesDir.parent.absolute.path;
    final String baseSha = argResults[_kBaseSha];

    GitDir baseGitDir = gitDir;
    if (baseGitDir == null) {
      if (!await GitDir.isGitDir(rootDir)) {
        print('$rootDir is not a valid Git repository.');
        throw ToolExit(2);
      }
      baseGitDir = await GitDir.fromExisting(rootDir);
    }

    final GitVersionFinder gitVersionFinder =
        GitVersionFinder(baseGitDir, baseSha);

    final List<String> changedPubspecs =
        await gitVersionFinder.getChangedPubSpecs();

    for (final String pubspecPath in changedPubspecs) {
      try {
        final File pubspecFile = fileSystem.file(pubspecPath);
        if (!pubspecFile.existsSync()) {
          continue;
        }
        final Pubspec pubspec = Pubspec.parse(pubspecFile.readAsStringSync());
        if (pubspec.publishTo == 'none') {
          continue;
        }

        final Version headVersion =
            await gitVersionFinder.getPackageVersion(pubspecPath, 'HEAD');
        if (headVersion == null) {
          continue; // Example apps don't have versions
        }
        if (pubspec.name == null || pubspec.version == null) {
          ThrowsToolExit(errorMessage: 'Fatal: Either package name or package version is null.');
        }
        final String release_tag = '${pubspec.name}-v${pubspec.version}';
        print('Tagging release $release_tag...');
        await processRunner.runAndExitOnError('git', <String>['tag', release_tag],
            workingDir: packagesDir);
        print('Successfully added tag $release_tag...');

        print('Pushing tag $release_tag...');
        await processRunner.runAndExitOnError('git', <String>['tag', release_tag],
            workingDir: packagesDir);
        print('Successfully pushed tag $release_tag.');

      } on io.ProcessException {
        print('Unable to find pubspec in master for $pubspecPath.'
            ' Safe to ignore if the project is new.');
      }
    }

    print('Successfully pushed all tags');
  }
}
