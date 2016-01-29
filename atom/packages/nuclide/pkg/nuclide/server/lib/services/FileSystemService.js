'use babel';
/* @flow */

/*
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the LICENSE file in
 * the root directory of this source tree.
 */

/**
 * This code implements the NuclideFs service.  It exports the FS on http via
 * the endpoint: http://your.server:your_port/fs/method where method is one of
 * readFile, writeFile, etc.
 */

const mv = require('mv');
const fs = require('fs');
const pathUtil = require('path');
const {fsPromise} = require('../../../commons');

import type {FileWithStats} from './FileSystemServiceType';


///////////////////
//
// Services
//
//////////////////

/**
 * Checks a certain path for existence and returns 'true'/'false' accordingly
 */
export function exists(path: string): Promise<boolean> {
  return fsPromise.exists(path);
}

export function findNearestFile(fileName: string, pathToDirectory: string): Promise<?string> {
  return fsPromise.findNearestFile(fileName, pathToDirectory);
}

/**
 * The lstat endpoint is the same as the stat endpoint except it will return
 * the stat of a link instead of the file the link points to.
 */
export function lstat(path: string): Promise<fs.Stats> {
  return fsPromise.lstat(path);
}

/**
 * Creates a new directory with the given path.
 * Throws EEXIST error if the directory already exists.
 * Throws ENOENT if the path given is nested in a non-existing directory.
 */
export function mkdir(path: string): Promise<void> {
  return fsPromise.mkdir(path);
}

/**
 * Runs the equivalent of `mkdir -p` with the given path.
 *
 * Like most implementations of mkdirp, if it fails, it is possible that
 * directories were created for some prefix of the given path.
 * @return true if the path was created; false if it already existed.
 */
export function mkdirp(path: string): Promise<boolean> {
  return fsPromise.mkdirp(path);
}

/**
 * If no file (or directory) at the specified path exists, creates the parent
 * directories (if necessary) and then writes an empty file at the specified
 * path.
 *
 * @return A boolean indicating whether the file was created.
 */
export async function newFile(filePath: string): Promise<boolean> {
  const isExistingFile = await fsPromise.exists(filePath);
  if (isExistingFile) {
    return false;
  }
  await fsPromise.mkdirp(pathUtil.dirname(filePath));
  await fsPromise.writeFile(filePath, '');
  return true;
}

/**
 * The readdir endpoint accepts the following query parameters:
 *
 *   path: path to the folder to list entries inside.
 *
 * Body contains a JSON encoded array of objects with file: and stats: entries.
 * file: has the file or directory name, stats: has the stats of the file/dir,
 * isSymbolicLink: true if the entry is a symlink to another filesystem location.
 */
export async function readdir(path: string): Promise<Array<FileWithStats>> {
  const files = await fsPromise.readdir(path);
  const entries = await Promise.all(files.map(async (file) => {
    const fullpath = pathUtil.join(path, file);
    const lstats = await fsPromise.lstat(fullpath);
    if (!lstats.isSymbolicLink()) {
      return {file, stats: lstats, isSymbolicLink: false};
    } else {
      try {
        const stats = await fsPromise.stat(fullpath);
        return {file, stats, isSymbolicLink: true};
      } catch (error) {
        return {file, stats: undefined, isSymbolicLink: true, error};
      }
    }
  }));
  // TODO: Return entries directly and change client to handle error.
  return entries.filter(entry => entry.error === undefined).
    map(entry => {
      return {file: entry.file, stats: entry.stats, isSymbolicLink: entry.isSymbolicLink};
    });
}

/**
 * Gets the real path of a file path.
 * It could be different than the given path if the file is a symlink
 * or exists in a symlinked directory.
 */
export function realpath(path: string): Promise<string> {
  return fsPromise.realpath(path);
}

export function resolveRealPath(path: string): Promise<string> {
  return fsPromise.realpath(fsPromise.expandHomeDir(path));
}

/**
 * Runs the equivalent of `mv sourcePath destinationPath`.
 */
export function rename(sourcePath: string, destinationPath: string): Promise {
  return new Promise((resolve, reject) => {
    const fsPlus = require('fs-plus');
    fsPlus.move(sourcePath, destinationPath, error => {
      error ? reject(error) : resolve();
    });
  });
}

/**
 * Runs the equivalent of `cp sourcePath destinationPath`.
 */
export async function copy(sourcePath: string, destinationPath: string): Promise<boolean> {
  const isExistingFile = await fsPromise.exists(destinationPath);
  if (isExistingFile) {
    return false;
  }
  await new Promise((resolve, reject) => {
    const fsPlus = require('fs-plus');
    fsPlus.copy(sourcePath, destinationPath, error => {
      error ? reject(error) : resolve();
    });
  });
  return true;
}

/**
 * Removes directories even if they are non-empty. Does not fail if the directory doesn't exist.
 */
export function rmdir(path: string): Promise<void> {
  return fsPromise.rmdir(path);
}

/**
 * The stat endpoint accepts the following query parameters:
 *
 *   path: path to the file to read
 *
 */
export function stat(path: string): Promise<fs.Stats> {
  return fsPromise.stat(path);
}

/**
 * Removes files. Does not fail if the file doesn't exist.
 */
export function unlink(path: string): Promise {
  return fsPromise.unlink(path).catch((error) => {
    if (error.code !== 'ENOENT') {
      throw error;
    }
  });
}

/**
 *   path: the path to the file to read
 *   options: options to pass to fs.readFile.
 *      Note that options does NOT include 'encoding' this ensures that the return value
 *      is always a Buffer and never a string.
 *
 *   Callers who want a string should call buffer.toString('utf8').
 */
export function readFile(path: string, options?: {flag?: string}):
    Promise<Buffer> {
  return fsPromise.readFile(path, options);
}

// TODO: Move to nuclide-commons
function mvPromise(sourcePath: string, destinationPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    mv(sourcePath, destinationPath, {mkdirp: false}, error => {
      if (error) {
        reject(error);
      } else {
        resolve();
      }
    });
  });
}

/**
 * The writeFile endpoint accepts the following query parameters:
 *
 *   path: path to the file to read (it must be url encoded).
 *   options: options to pass to fs.writeFile
 *
 * TODO: move to nuclide-commons and rename to writeFileAtomic
 */
export async function writeFile(path: string, data: string,
    options: ?{encoding?: string; mode?: number; flag?:string}): Promise<void> {

  let complete = false;
  const tempFilePath = await fsPromise.tempfile('nuclide');
  try {
    await fsPromise.writeFile(tempFilePath, data, options);

    // Ensure file still has original permissions:
    // https://github.com/facebook/nuclide/issues/157
    // We update the mode of the temp file rather than the destination file because
    // if we did the mv() then the chmod(), there would be a brief period between
    // those two operations where the destination file might have the wrong permissions.
    let permissions = null;
    try {
      permissions = (await fsPromise.stat(path)).mode;
    } catch (e) {
      // If the file does not exist, then ENOENT will be thrown.
      if (e.code !== 'ENOENT') {
        throw e;
      }
    }
    if (permissions != null) {
      await fsPromise.chmod(tempFilePath, permissions);
    }

    // TODO(mikeo): put renames into a queue so we don't write older save over new save.
    // Use mv as fs.rename doesn't work across partitions.
    await mvPromise(tempFilePath, path);
    complete = true;
  } finally {
    if (!complete) {
      await fsPromise.unlink(tempFilePath);
    }
  }
}
