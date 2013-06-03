chrome.app.runtime.onLaunched.addListener(function() {
  chrome.app.window.create('web/daxe.html', {
    'width': 800,
    'height': 800
  });
});
