# Copyright (c) 2015-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the LICENSE file in
# the root directory of this source tree.

"""
Set of lldb commands for serializing debug information into JSON.
"""

import file_manager
import lldb


def _BreakpointEventType_to_string(event):
    """Converts lldb.BreakpointEventType to a string"""
    return {
      lldb.eBreakpointEventTypeAdded: 'added',
      lldb.eBreakpointEventTypeCommandChanged: 'command-changed',
      lldb.eBreakpointEventTypeConditionChanged: 'condition-changed',
      lldb.eBreakpointEventTypeDisabled: 'disabled',
      lldb.eBreakpointEventTypeEnabled: 'enabled',
      lldb.eBreakpointEventTypeIgnoreChanged: 'ignore-changed',
      lldb.eBreakpointEventTypeInvalidType: 'invalid-type',
      lldb.eBreakpointEventTypeLocationsAdded: 'locations-added',
      lldb.eBreakpointEventTypeLocationsRemoved: 'locations-removed',
      lldb.eBreakpointEventTypeLocationsResolved: 'locations-resolved',
      lldb.eBreakpointEventTypeRemoved: 'removed',
      lldb.eBreakpointEventTypeThreadChanged: 'thread-changed',
    }[event]


def _WatchpointEventType_to_string(event):
  """Converts lldb.BreakpointEventType to a string"""
  return {
    lldb.eWatchpointEventTypeAdded: 'added',
    lldb.eWatchpointEventTypeCommandChanged: 'command-changed',
    lldb.eWatchpointEventTypeConditionChanged: 'condition-changed',
    lldb.eWatchpointEventTypeDisabled: 'disabled',
    lldb.eWatchpointEventTypeEnabled: 'enabled',
    lldb.eWatchpointEventTypeIgnoreChanged: 'ignore-changed',
    lldb.eWatchpointEventTypeInvalidType: 'invalid-type',
    lldb.eWatchpointEventTypeRemoved: 'removed',
    lldb.eWatchpointEventTypeThreadChanged: 'thread-changed',
    lldb.eWatchpointEventTypeTypeChanged: 'type-changed',
  }[event]


def StopReason_to_string(reason):
    """Converts lldb.StopReason to a string"""
    return {
      lldb.eStopReasonInvalid: 'invalid',
      lldb.eStopReasonNone: 'none',
      lldb.eStopReasonTrace: 'trace',
      lldb.eStopReasonBreakpoint: 'breakpoint',
      lldb.eStopReasonWatchpoint: 'watchpoint',
      lldb.eStopReasonSignal: 'signal',
      lldb.eStopReasonException: 'exception',
      lldb.eStopReasonPlanComplete: 'plan-complete',
    }[reason]


class LocationSerializer:
    def __init__(self, file_manager, basepath='.'):
        self._file_manager = file_manager
        self._basepath = basepath

    def get_frame_location(self, frame):
        """Serialize the location of the current frame.

        Returns file and line information if source is available. Otherwise,
        returns the location in the disassembled assembly listing.
        """
        target = frame.GetThread().GetProcess().GetTarget()
        serialized = self.from_line_entry(frame.line_entry)
        if serialized is not None:
            return serialized
        elif frame.symbol.IsValid():
            func = self._file_manager.register_filelike(
                file_manager.FunctionAssembly(target, frame.symbol))
            return {
                'scriptId': func.script_id,
                'columnNumber': 0,
                'lineNumber': func.get_line_for_pc(frame.GetPCAddress()),
            }
        else:
            return None

    def get_breakpoint_locations(self, breakpoint):
        """Serialize the locations of a breakpoint.

        Returns a list of serialized locations.
        """
        return [
            self.from_line_entry(bpl.GetAddress().line_entry)
            for bpl in breakpoint
        ]

    def from_line_entry(self, entry):
        """Attempt to serialize the location of a SBLineEntry.

        Returns the serialized location dictionary, or None if the line entry
        cannot be serialized.
        """
        if entry.file.fullpath:
            file = self._file_manager.register_filelike(
                file_manager.File.from_filespec(entry.file, self._basepath))
            return {
                'columnNumber': entry.column,
                'lineNumber': entry.line - 1,  # Chrome lines start at 0
                'scriptId': file.script_id,
            }
        else:
            return None
