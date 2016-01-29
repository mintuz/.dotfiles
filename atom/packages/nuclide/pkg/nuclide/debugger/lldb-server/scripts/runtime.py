# Copyright (c) 2015-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the LICENSE file in
# the root directory of this source tree.

"""
Defines methods for the Runtime domain.
https://developer.chrome.com/devtools/docs/protocol/1.1/runtime#command-evaluate
"""
import lldb

from handler import HandlerDomain, handler
from page_domain import DUMMY_FRAME_ID
import value_serializer


class RuntimeDomain(HandlerDomain):
    def __init__(self, remote_object_manager, **kwargs):
        HandlerDomain.__init__(self, **kwargs)
        self._remote_object_manager = remote_object_manager

    @property
    def name(self):
        return 'Runtime'

    @handler()
    def enable(self, params):
        self._notifyExecutionContext()
        return {}

    @handler()
    def evaluate(self, params):
        # Cast to string from possible unicode.
        command = str(params['expression'])

        # `objectGroups` are used by the client to designate remote objects on
        # the server that should stick around (for potential future queries),
        # and eventually released with a `releaseObjectGroup` call.
        #
        # Incidentally, they have names denoting which part of the client made
        # the request. We use these names to disambiguate LLDB commands from
        # C-style expressions.
        if params['objectGroup'] == 'console':
            result = lldb.SBCommandReturnObject()
            self.debugger.GetCommandInterpreter().HandleCommand(command, result)

            return {
                'result': {
                    'value': result.GetOutput() + result.GetError()
                },
                'wasThrown': False,
            }
        elif params['objectGroup'] == 'watch-group':
            frame = self.debugger.GetSelectedTarget().process.GetSelectedThread().GetSelectedFrame()
            value = frame.EvaluateExpression(command)
            # `value.error` is an `SBError` instance which captures whether the
            # result had an error. `SBError.success` denotes no error.
            if value.error.success:
                return {
                    'result': value_serializer.serialize_value(
                        value,
                        self._remote_object_manager.get_add_object_func(params['objectGroup'])),
                    'wasThrown': False,
                }
            else:
                return {
                    'result': {
                        'type': 'undefined',
                    },
                    'wasThrown': True,
                    'exceptionDetails': {
                        'text': value.error.description,
                    }
                }
        return {
            'result': {},
            'wasThrown': False,
        }

    @handler()
    def getProperties(self, params):
        """Returns properties of a given object.

        Object group of the result is inherited from the target object.

        Params:
            objectId RemoteObjectId
                Identifier of the object to return properties for.
            ownProperties boolean
                If true, returns properties belonging only to the element
                itself, not to its prototype chain.
            accessorPropertiesOnly boolean
                If true, returns accessor properties (with getter/setter) only;
                internal properties are not returned either.
            generatePreview	boolean
                Whether preview should be generated for the results.
        """
        obj = self._remote_object_manager.get_object(params['objectId'])
        if obj and not params.get('accessorPropertiesOnly', False):
            return obj.properties
        else:
            return {'result': []}

    def _notifyExecutionContext(self):
        # Send a notification context with frame id of the dummy frame sent by
        # Page.getResourceTree.
        selectedTarget = self.debugger.GetSelectedTarget()
        if selectedTarget.IsValid():
            filename = self.debugger.GetSelectedTarget().executable.basename
            pid = self.debugger.GetSelectedTarget().process.id
            name = 'LLDB - %s (%d)' % (filename, pid)
        else:
            name = 'LLDB - no target'
        self.socket.send_notification(
            'Runtime.executionContextCreated',
            params={
                'context': {
                    'id': 1,
                    'frameId': DUMMY_FRAME_ID,
                    'name': name,
                },
            })
