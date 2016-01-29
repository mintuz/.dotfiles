/*
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the LICENSE file in
 * the root directory of this source tree.
 */

declare class connect$Error extends Error {
  code?: number;
}

type connect$ServerHandle = connect$HandleFunction | http$fixed$Server;
type connect$SimpleHandleFunction =
  // $FlowFixMe (peterhal)
  (req: http$fixed$IncomingMessage, res: http$fixed$ServerResponse) => mixed;
type connect$NextHandleFunction =
  // $FlowFixMe (peterhal)
  (req: http$fixed$IncomingMessage, res: http$fixed$ServerResponse, next: Function) => mixed;
type connect$ErrorHandleFunction = (err: ?connect$Error, req: http$fixed$IncomingMessage,
  res: http$fixed$ServerResponse, next: Function) => mixed;
type connect$HandleFunction =
  connect$SimpleHandleFunction | connect$NextHandleFunction | connect$ErrorHandleFunction;

type connect$ServerStackItem = {
   route: string;
   handle: connect$ServerHandle;
};

declare class connect$Server {
  (req: http$fixed$IncomingMessage, res: http$fixed$ServerResponse, next?: Function): void;

  route: string;
  stack: Array<connect$ServerStackItem>;

  /**
  * Utilize the given middleware `handle` to the given `route`,
  * defaulting to _/_. This "route" is the mount-point for the
  * middleware, when given a value other than _/_ the middleware
  * is only effective when that segment is present in the request's
  * pathname.
  *
  * For example if we were to mount a function at _/admin_, it would
  * be invoked on _/admin_, and _/admin/settings_, however it would
  * not be invoked for _/_, or _/posts_.
  *
  * @public
  */
  use(fn: connect$HandleFunction): connect$Server;
  use(route: string, fn: connect$HandleFunction): connect$Server;

  /**
  * Handle server requests, punting them down
  * the middleware stack.
  *
  * @private
  */
  handle(req: http$fixed$IncomingMessage, res: http$fixed$ServerResponse, next: Function): void;

  /**
  * Listen for connections.
  *
  * This method takes the same arguments
  * as node's `http$fixed$Server#listen()`.
  *
  * HTTP and HTTPS:
  *
  * If you run your application both as HTTP
  * and HTTPS you may wrap them individually,
  * since your Connect "server" is really just
  * a JavaScript `Function`.
  *
  *      var connect = require('connect')
  *        , http = require('http')
  *        , https = require('https');
  *
  *      var app = connect();
  *
  *      http$fixed$createServer(app).listen(80);
  *      https.createServer(options, app).listen(443);
  *
  * @api public
  */
  listen(port: number, hostname?: string, backlog?: number, callback?: Function): http$fixed$Server;
  listen(port: number, hostname?: string, callback?: Function): http$fixed$Server;
  listen(path: string, callback?: Function): http$fixed$Server;
  listen(handle: any, listeningListener?: Function): http$fixed$Server;
}

type connect$module = () => connect$Server;
