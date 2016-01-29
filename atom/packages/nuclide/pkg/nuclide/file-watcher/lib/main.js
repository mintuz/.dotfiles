
var subscriptions = null;

/*
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the LICENSE file in
 * the root directory of this source tree.
 */

var watchers = null;

module.exports = {

  activate: function activate(state) {
    var _require = require('atom');

    var CompositeDisposable = _require.CompositeDisposable;

    var _subscriptions = new CompositeDisposable();
    var _watchers = new Map();

    _subscriptions.add(atom.workspace.observeTextEditors(function (editor) {
      if (_watchers.has(editor)) {
        return;
      }

      var FileWatcher = require('./FileWatcher');
      var fileWatcher = new FileWatcher(editor);
      _watchers.set(editor, fileWatcher);

      _subscriptions.add(editor.onDidDestroy(function () {
        fileWatcher.destroy();
        _watchers['delete'](editor);
      }));
    }));

    watchers = _watchers;
    subscriptions = _subscriptions;

    // Disable the file-watcher package from showing the promot, if installed.
    atom.config.set('file-watcher.promptWhenFileHasChangedOnDisk', false);
  },

  deactivate: function deactivate() {
    if (subscriptions == null || watchers == null) {
      return;
    }
    for (var fileWatcher of watchers.values()) {
      fileWatcher.destroy();
    }
    subscriptions.dispose();
    subscriptions = null;
  }
};
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm1haW4uanMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IjtBQVlBLElBQUksYUFBdUMsR0FBRyxJQUFJLENBQUM7Ozs7Ozs7Ozs7QUFDbkQsSUFBSSxRQUFjLEdBQUcsSUFBSSxDQUFDOztBQUUxQixNQUFNLENBQUMsT0FBTyxHQUFHOztBQUVmLFVBQVEsRUFBQSxrQkFBQyxLQUFjLEVBQVE7bUJBQ0MsT0FBTyxDQUFDLE1BQU0sQ0FBQzs7UUFBdEMsbUJBQW1CLFlBQW5CLG1CQUFtQjs7QUFFMUIsUUFBTSxjQUFjLEdBQUcsSUFBSSxtQkFBbUIsRUFBRSxDQUFDO0FBQ2pELFFBQU0sU0FBUyxHQUFHLElBQUksR0FBRyxFQUFFLENBQUM7O0FBRTVCLGtCQUFjLENBQUMsR0FBRyxDQUFDLElBQUksQ0FBQyxTQUFTLENBQUMsa0JBQWtCLENBQUMsVUFBQSxNQUFNLEVBQUk7QUFDN0QsVUFBSSxTQUFTLENBQUMsR0FBRyxDQUFDLE1BQU0sQ0FBQyxFQUFFO0FBQ3pCLGVBQU87T0FDUjs7QUFFRCxVQUFNLFdBQVcsR0FBRyxPQUFPLENBQUMsZUFBZSxDQUFDLENBQUM7QUFDN0MsVUFBTSxXQUFXLEdBQUcsSUFBSSxXQUFXLENBQUMsTUFBTSxDQUFDLENBQUM7QUFDNUMsZUFBUyxDQUFDLEdBQUcsQ0FBQyxNQUFNLEVBQUUsV0FBVyxDQUFDLENBQUM7O0FBRW5DLG9CQUFjLENBQUMsR0FBRyxDQUFDLE1BQU0sQ0FBQyxZQUFZLENBQUMsWUFBTTtBQUMzQyxtQkFBVyxDQUFDLE9BQU8sRUFBRSxDQUFDO0FBQ3RCLGlCQUFTLFVBQU8sQ0FBQyxNQUFNLENBQUMsQ0FBQztPQUMxQixDQUFDLENBQUMsQ0FBQztLQUNMLENBQUMsQ0FBQyxDQUFDOztBQUVKLFlBQVEsR0FBRyxTQUFTLENBQUM7QUFDckIsaUJBQWEsR0FBRyxjQUFjLENBQUM7OztBQUcvQixRQUFJLENBQUMsTUFBTSxDQUFDLEdBQUcsQ0FBQyw2Q0FBNkMsRUFBRSxLQUFLLENBQUMsQ0FBQztHQUN2RTs7QUFFRCxZQUFVLEVBQUEsc0JBQVM7QUFDakIsUUFBSSxhQUFhLElBQUksSUFBSSxJQUFJLFFBQVEsSUFBSSxJQUFJLEVBQUU7QUFDN0MsYUFBTztLQUNSO0FBQ0QsU0FBSyxJQUFNLFdBQVcsSUFBSSxRQUFRLENBQUMsTUFBTSxFQUFFLEVBQUU7QUFDM0MsaUJBQVcsQ0FBQyxPQUFPLEVBQUUsQ0FBQztLQUN2QjtBQUNELGlCQUFhLENBQUMsT0FBTyxFQUFFLENBQUM7QUFDeEIsaUJBQWEsR0FBRyxJQUFJLENBQUM7R0FDdEI7Q0FDRixDQUFDIiwiZmlsZSI6Im1haW4uanMiLCJzb3VyY2VzQ29udGVudCI6WyIndXNlIGJhYmVsJztcbi8qIEBmbG93ICovXG5cbi8qXG4gKiBDb3B5cmlnaHQgKGMpIDIwMTUtcHJlc2VudCwgRmFjZWJvb2ssIEluYy5cbiAqIEFsbCByaWdodHMgcmVzZXJ2ZWQuXG4gKlxuICogVGhpcyBzb3VyY2UgY29kZSBpcyBsaWNlbnNlZCB1bmRlciB0aGUgbGljZW5zZSBmb3VuZCBpbiB0aGUgTElDRU5TRSBmaWxlIGluXG4gKiB0aGUgcm9vdCBkaXJlY3Rvcnkgb2YgdGhpcyBzb3VyY2UgdHJlZS5cbiAqL1xuXG5pbXBvcnQgdHlwZSB7Q29tcG9zaXRlRGlzcG9zYWJsZSBhcyBDb21wb3NpdGVEaXNwb3NhYmxlVHlwZX0gZnJvbSAnYXRvbSc7XG5sZXQgc3Vic2NyaXB0aW9uczogP0NvbXBvc2l0ZURpc3Bvc2FibGVUeXBlID0gbnVsbDtcbmxldCB3YXRjaGVyczogP01hcCA9IG51bGw7XG5cbm1vZHVsZS5leHBvcnRzID0ge1xuXG4gIGFjdGl2YXRlKHN0YXRlOiA/T2JqZWN0KTogdm9pZCB7XG4gICAgY29uc3Qge0NvbXBvc2l0ZURpc3Bvc2FibGV9ID0gcmVxdWlyZSgnYXRvbScpO1xuXG4gICAgY29uc3QgX3N1YnNjcmlwdGlvbnMgPSBuZXcgQ29tcG9zaXRlRGlzcG9zYWJsZSgpO1xuICAgIGNvbnN0IF93YXRjaGVycyA9IG5ldyBNYXAoKTtcblxuICAgIF9zdWJzY3JpcHRpb25zLmFkZChhdG9tLndvcmtzcGFjZS5vYnNlcnZlVGV4dEVkaXRvcnMoZWRpdG9yID0+IHtcbiAgICAgIGlmIChfd2F0Y2hlcnMuaGFzKGVkaXRvcikpIHtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuXG4gICAgICBjb25zdCBGaWxlV2F0Y2hlciA9IHJlcXVpcmUoJy4vRmlsZVdhdGNoZXInKTtcbiAgICAgIGNvbnN0IGZpbGVXYXRjaGVyID0gbmV3IEZpbGVXYXRjaGVyKGVkaXRvcik7XG4gICAgICBfd2F0Y2hlcnMuc2V0KGVkaXRvciwgZmlsZVdhdGNoZXIpO1xuXG4gICAgICBfc3Vic2NyaXB0aW9ucy5hZGQoZWRpdG9yLm9uRGlkRGVzdHJveSgoKSA9PiB7XG4gICAgICAgIGZpbGVXYXRjaGVyLmRlc3Ryb3koKTtcbiAgICAgICAgX3dhdGNoZXJzLmRlbGV0ZShlZGl0b3IpO1xuICAgICAgfSkpO1xuICAgIH0pKTtcblxuICAgIHdhdGNoZXJzID0gX3dhdGNoZXJzO1xuICAgIHN1YnNjcmlwdGlvbnMgPSBfc3Vic2NyaXB0aW9ucztcblxuICAgIC8vIERpc2FibGUgdGhlIGZpbGUtd2F0Y2hlciBwYWNrYWdlIGZyb20gc2hvd2luZyB0aGUgcHJvbW90LCBpZiBpbnN0YWxsZWQuXG4gICAgYXRvbS5jb25maWcuc2V0KCdmaWxlLXdhdGNoZXIucHJvbXB0V2hlbkZpbGVIYXNDaGFuZ2VkT25EaXNrJywgZmFsc2UpO1xuICB9LFxuXG4gIGRlYWN0aXZhdGUoKTogdm9pZCB7XG4gICAgaWYgKHN1YnNjcmlwdGlvbnMgPT0gbnVsbCB8fCB3YXRjaGVycyA9PSBudWxsKSB7XG4gICAgICByZXR1cm47XG4gICAgfVxuICAgIGZvciAoY29uc3QgZmlsZVdhdGNoZXIgb2Ygd2F0Y2hlcnMudmFsdWVzKCkpIHtcbiAgICAgIGZpbGVXYXRjaGVyLmRlc3Ryb3koKTtcbiAgICB9XG4gICAgc3Vic2NyaXB0aW9ucy5kaXNwb3NlKCk7XG4gICAgc3Vic2NyaXB0aW9ucyA9IG51bGw7XG4gIH0sXG59O1xuIl19