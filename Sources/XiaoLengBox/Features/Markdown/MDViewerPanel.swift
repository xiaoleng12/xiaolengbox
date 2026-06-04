import AppKit
import WebKit
import UniformTypeIdentifiers

class MDViewerPanel: NSView, WKScriptMessageHandler {
    private var webView: WKWebView!
    private let fileLabel = NSTextField(labelWithString: "未打开文件")
    var onMDLoaded: (([MDOutlineItem]) -> Void)?
    private var currentURL: URL?

    override init(frame: NSRect) { super.init(frame: frame); setupUI() }
    required init?(coder: NSCoder) { super.init(coder: coder); setupUI() }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(white: 0.15, alpha: 1.0).cgColor

        let toolbar = NSView()
        toolbar.wantsLayer = true
        toolbar.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        fileLabel.font = .systemFont(ofSize: 12)
        fileLabel.textColor = .white
        fileLabel.lineBreakMode = .byTruncatingMiddle
        fileLabel.translatesAutoresizingMaskIntoConstraints = false

        let saveBtn = NSButton(title: "保存 (Cmd+S)", target: self, action: #selector(saveMD))
        saveBtn.bezelStyle = .rounded
        saveBtn.translatesAutoresizingMaskIntoConstraints = false

        toolbar.addSubview(fileLabel)
        toolbar.addSubview(saveBtn)
        NSLayoutConstraint.activate([
            fileLabel.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 12),
            fileLabel.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            saveBtn.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -12),
            saveBtn.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor)
        ])

        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "mdHandler")
        userContentController.add(self, name: "outline")
        userContentController.add(self, name: "imagePicker")
        config.userContentController = userContentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        if #available(macOS 13.3, *) {
            webView.isInspectable = true
        }
        webView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(toolbar)
        addSubview(webView)
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 36),

            webView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "mdHandler", let mdString = message.body as? String {
            if let url = currentURL {
                try? mdString.write(to: url, atomically: true, encoding: .utf8)
                let originalText = fileLabel.stringValue
                fileLabel.stringValue = originalText + " (已保存)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    if self?.fileLabel.stringValue.hasSuffix("(已保存)") == true {
                        self?.fileLabel.stringValue = originalText
                    }
                }
            }
        } else if message.name == "outline", let jsonString = message.body as? String {
            guard let jsonData = jsonString.data(using: .utf8),
                  let rawItems = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else { return }
            var items: [MDOutlineItem] = []
            for raw in rawItems {
                if let title = raw["title"] as? String, let level = raw["level"] as? Int {
                    items.append(MDOutlineItem(title: title, level: level))
                }
            }
            onMDLoaded?(items)
        } else if message.name == "imagePicker" {
            openImagePicker()
        }
    }

    @objc private func saveMD() {
        webView.evaluateJavaScript("vditor.getValue()") { [weak self] result, error in
            if let mdString = result as? String, let url = self?.currentURL {
                try? mdString.write(to: url, atomically: true, encoding: .utf8)
                let originalText = self?.fileLabel.stringValue ?? ""
                self?.fileLabel.stringValue = originalText + " (已保存)"
                self?.webView?.evaluateJavaScript("(function(){var e=document.getElementById('si');e.textContent='已保存';setTimeout(function(){e.textContent='Cmd+S 保存';},2000);})();")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self?.fileLabel.stringValue.hasSuffix("(已保存)") == true {
                        self?.fileLabel.stringValue = originalText
                    }
                }
            }
        }
    }

    private func percentEncodedPathComponent(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }

    private func markdownImageReference(for imageURL: URL) -> String? {
        guard let mdURL = currentURL else { return nil }

        let fm = FileManager.default
        let mdDir = mdURL.deletingLastPathComponent()
        let assetDirName = "\(mdURL.deletingPathExtension().lastPathComponent)_assets"
        let assetDir = mdDir.appendingPathComponent(assetDirName, isDirectory: true)

        do {
            try fm.createDirectory(at: assetDir, withIntermediateDirectories: true)

            let ext = imageURL.pathExtension
            let base = imageURL.deletingPathExtension().lastPathComponent
            var fileName = imageURL.lastPathComponent
            var destURL = assetDir.appendingPathComponent(fileName)
            if fm.fileExists(atPath: destURL.path) {
                let suffix = UUID().uuidString.prefix(8)
                fileName = ext.isEmpty ? "\(base)-\(suffix)" : "\(base)-\(suffix).\(ext)"
                destURL = assetDir.appendingPathComponent(fileName)
            }

            try fm.copyItem(at: imageURL, to: destURL)

            let relPath = "\(percentEncodedPathComponent(assetDirName))/\(percentEncodedPathComponent(fileName))"
            let alt = destURL.deletingPathExtension().lastPathComponent
            return "![\(alt)](\(relPath))"
        } catch {
            let alert = NSAlert()
            alert.messageText = "无法插入图片"
            alert.informativeText = error.localizedDescription
            alert.runModal()
            return nil
        }
    }

    private func openImagePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        panel.message = "选择要插入的图片"

        guard panel.runModal() == .OK, let imageURL = panel.url,
              let markdown = markdownImageReference(for: imageURL) else { return }

        let js = "insertMarkdown(\(jsStringLiteral(markdown + "\n")));"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func jsStringLiteral(_ value: String) -> String {
        if let data = try? JSONEncoder().encode(value),
           let literal = String(data: data, encoding: .utf8) {
            return literal
        }
        return "\"\""
    }

    private func getHTMLTemplate(content: String, editorID: String, cacheID: String) -> String {
        let contentLiteral = jsStringLiteral(content)
        let editorIDLiteral = jsStringLiteral(editorID)
        let cacheIDLiteral = jsStringLiteral(cacheID)

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/vditor@3.11.2/dist/index.css">
        <style>
        *{margin:0;padding:0;box-sizing:border-box}
        html,body{height:100%;overflow:hidden;background:#f5f5f5}
        body{font-family:-apple-system,BlinkMacSystemFont,'Helvetica Neue','PingFang SC',sans-serif;display:flex;flex-direction:column}
        .md-controlbar{display:flex;align-items:center;gap:6px;flex-wrap:wrap;padding:6px 10px;background:#f9fafb;border-bottom:1px solid #e5e7eb;flex-shrink:0}
        .md-controlbar select,.md-controlbar button{height:26px;border:1px solid #d1d5db;border-radius:4px;background:#fff;color:#374151;font-size:12px;padding:0 8px}
        .md-controlbar button{min-width:32px;cursor:pointer}
        .md-controlbar button:hover,.md-controlbar select:hover{background:#f3f4f6}
        .md-controlbar .split{width:1px;height:18px;background:#d1d5db;margin:0 2px}
        #\(editorID){flex:1;min-height:0}
        .vditor{height:100%!important;border:none!important;border-radius:0!important;display:flex;flex-direction:column}
        .vditor-toolbar{background:#fff!important;border-bottom:1px solid #e0e0e0!important;padding:4px 8px!important;flex-shrink:0}
        .vditor-toolbar__item svg{fill:#555!important}
        .vditor-toolbar__item:hover{background:#f0f0f0!important}
        .vditor-toolbar__item--current{background:#e3f2fd!important}
        .vditor-toolbar__divider{border-left:1px solid #e0e0e0!important;margin:0 4px!important}
        .vditor-content{flex:1;overflow-y:auto!important;min-height:0}
        .vditor-wysiwyg{background:#fafafa!important;color:#333!important;padding:24px 32px!important;font-family:var(--md-font-family,-apple-system,BlinkMacSystemFont,'Helvetica Neue','PingFang SC',sans-serif)!important;font-size:var(--md-font-size,16px)!important;line-height:var(--md-line-height,1.75)!important;min-height:100%}
        .vditor-wysiwyg h1{font-size:1.9em;border-bottom:1px solid #ddd;padding-bottom:.3em;margin:1em 0 .5em;color:#111}
        .vditor-wysiwyg h2{font-size:1.5em;border-bottom:1px solid #eee;padding-bottom:.25em;margin:.9em 0 .4em;color:#222}
        .vditor-wysiwyg h3{font-size:1.25em;margin:.8em 0 .4em;color:#333}
        .vditor-wysiwyg h4{font-size:1.1em;margin:.7em 0 .3em;color:#444}
        .vditor-wysiwyg h5,.vditor-wysiwyg h6{margin:.6em 0 .2em;color:#555}
        .vditor-wysiwyg p{margin:.6em 0}
        .vditor-wysiwyg a{color:#1a6fc4;text-decoration:none}
        .vditor-wysiwyg strong{color:#111;font-weight:700}
        .vditor-wysiwyg code{background:#f0f0f0;padding:2px 6px;border-radius:3px;font-family:'SF Mono','Menlo',monospace;font-size:.9em;color:#c7254e}
        .vditor-wysiwyg pre{background:#f4f4f4;border-radius:8px;padding:14px;margin:.8em 0;overflow-x:auto;border:1px solid #e0e0e0}
        .vditor-wysiwyg pre code{background:none;padding:0;color:#333;font-size:.88em}
        .vditor-wysiwyg blockquote{border-left:4px solid #1a6fc4;margin:.8em 0;padding:8px 16px;color:#555;background:#f5f7fa;border-radius:0 4px 4px 0}
        .vditor-wysiwyg ul,.vditor-wysiwyg ol{padding-left:1.8em;margin:.5em 0}
        .vditor-wysiwyg li{margin:.25em 0}
        .vditor-wysiwyg table{border-collapse:collapse;margin:.8em 0;width:100%}
        .vditor-wysiwyg th,.vditor-wysiwyg td{border:1px solid #ddd;padding:8px 12px;text-align:left}
        .vditor-wysiwyg th{background:#f0f0f0;font-weight:600;color:#333}
        .vditor-wysiwyg img{max-width:100%;border-radius:6px;margin:.5em 0}
        .vditor-wysiwyg hr{border:none;border-top:1px solid #ddd;margin:1.5em 0}
        .vditor-wysiwyg del{color:#999}
        .statusbar{display:flex;justify-content:space-between;padding:4px 16px;background:#2d2d2d;border-top:1px solid #404040;font-size:11px;color:#888;flex-shrink:0}
        </style>
        </head>
        <body>
        <div class="md-controlbar">
          <select id="fontFamily">
            <option value="system">系统字体</option>
            <option value="serif">宋体</option>
            <option value="sans">黑体</option>
            <option value="mono">等宽</option>
          </select>
          <select id="fontSize">
            <option value="14">14px</option>
            <option value="16" selected>16px</option>
            <option value="18">18px</option>
            <option value="20">20px</option>
            <option value="22">22px</option>
          </select>
          <select id="lineHeight">
            <option value="1.5">1.5</option>
            <option value="1.75" selected>1.75</option>
            <option value="2">2.0</option>
          </select>
          <span class="split"></span>
          <button type="button" data-md="# 标题 1\\n">H1</button>
          <button type="button" data-md="## 标题 2\\n">H2</button>
          <button type="button" data-md="### 标题 3\\n">H3</button>
          <span class="split"></span>
          <button type="button" data-md="> 引用内容\\n">引用</button>
          <button type="button" data-md="- [ ] 待办事项\\n">待办</button>
          <button type="button" data-md="| 列 1 | 列 2 |\\n| --- | --- |\\n| 内容 | 内容 |\\n">表格</button>
          <button type="button" data-md="\\n```text\\n代码\\n```\\n">代码块</button>
          <button type="button" data-md="[链接文字](https://)\\n">链接</button>
          <button type="button" id="imageButton">图片</button>
          <button type="button" data-md="\\n---\\n">分割线</button>
        </div>
        <div id="\(editorID)"></div>
        <div class="statusbar">
          <span id="info">0 字</span>
          <span id="si">Cmd+S 保存</span>
        </div>
        <script src="https://cdn.jsdelivr.net/npm/vditor@3.11.2/dist/index.min.js"></script>
        <script>
        var vditor = new Vditor(\(editorIDLiteral), {
          mode: 'wysiwyg',
          theme: 'classic',
          cache: { enable: false, id: \(cacheIDLiteral) },
          value: \(contentLiteral),
          height: '100%',
          placeholder: '开始输入 Markdown ...',
          toolbar: [
            'emoji', 'headings', 'bold', 'italic', 'strike', 'line', '|',
            'quote', 'list', 'ordered-list', 'check', 'outdent', 'indent', '|',
            'code', 'inline-code', '|',
            'link', 'table', '|',
            'undo', 'redo', 'fullscreen', 'edit-mode', '|',
            'outline'
          ],
          counter: { enable: true },
          after: function() {
            applyEditorPreferences();
            emitOutline();
            document.getElementById('info').textContent = vditor.vditor.counter.renderElement.textContent.replace(/\\D/g, '') + ' 字';
          }
        });

        var fontFamilies = {
          system: "-apple-system,BlinkMacSystemFont,'Helvetica Neue','PingFang SC',sans-serif",
          serif: "'Songti SC','STSong',serif",
          sans: "'PingFang SC','Microsoft YaHei',sans-serif",
          mono: "'SF Mono','Menlo','Monaco',monospace"
        };

        function setEditorPreference(key, value) {
          try { localStorage.setItem('mdPref.' + key, value); } catch(e) {}
        }

        function getEditorPreference(key, fallback) {
          try { return localStorage.getItem('mdPref.' + key) || fallback; } catch(e) { return fallback; }
        }

        function applyEditorPreferences() {
          var fontFamily = getEditorPreference('fontFamily', 'system');
          var fontSize = getEditorPreference('fontSize', '16');
          var lineHeight = getEditorPreference('lineHeight', '1.75');
          document.documentElement.style.setProperty('--md-font-family', fontFamilies[fontFamily] || fontFamilies.system);
          document.documentElement.style.setProperty('--md-font-size', fontSize + 'px');
          document.documentElement.style.setProperty('--md-line-height', lineHeight);
          document.getElementById('fontFamily').value = fontFamily;
          document.getElementById('fontSize').value = fontSize;
          document.getElementById('lineHeight').value = lineHeight;
        }

        function insertMarkdown(md) {
          try {
            vditor.focus();
            if (typeof vditor.insertMD === 'function') {
              vditor.insertMD(md);
            } else if (typeof vditor.insertValue === 'function') {
              vditor.insertValue(md);
            }
            setTimeout(emitOutline, 250);
          } catch(e) {
            console.error(e);
          }
        }

        document.querySelectorAll('.md-controlbar button[data-md]').forEach(function(button) {
          button.addEventListener('mousedown', function(e) { e.preventDefault(); });
          button.addEventListener('click', function() {
            insertMarkdown((button.getAttribute('data-md') || '').replace(/\\\\n/g, '\\n'));
          });
        });

        document.getElementById('imageButton').addEventListener('mousedown', function(e) { e.preventDefault(); });
        document.getElementById('imageButton').addEventListener('click', function() {
          try { window.webkit.messageHandlers.imagePicker.postMessage('open'); } catch(e) {}
        });

        ['fontFamily', 'fontSize', 'lineHeight'].forEach(function(id) {
          document.getElementById(id).addEventListener('change', function(e) {
            setEditorPreference(id, e.target.value);
            applyEditorPreferences();
          });
        });

        function emitOutline() {
          setTimeout(function() {
            var hs = document.querySelectorAll('.vditor-wysiwyg h1, .vditor-wysiwyg h2, .vditor-wysiwyg h3, .vditor-wysiwyg h4, .vditor-wysiwyg h5, .vditor-wysiwyg h6');
            var items = [];
            for (var i = 0; i < hs.length; i++) {
              items.push({title: hs[i].textContent.trim(), level: +hs[i].tagName[1]});
            }
            try { window.webkit.messageHandlers.outline.postMessage(JSON.stringify(items)); } catch(e) {}
          }, 100);
        }

        document.addEventListener('input', function() {
          setTimeout(function() {
            try { document.getElementById('info').textContent = vditor.vditor.counter.renderElement.textContent.replace(/\\D/g, '') + ' 字'; } catch(e) {}
          }, 150);
          setTimeout(emitOutline, 500);
        });

        document.addEventListener('keydown', function(e) {
          if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 's') {
            e.preventDefault();
            window.webkit.messageHandlers.mdHandler.postMessage(vditor.getValue());
            var el = document.getElementById('si');
            el.textContent = '\\u5DF2\\u4FDD\\u5B58';
            setTimeout(function() { el.textContent = 'Cmd+S \\u4FDD\\u5B58'; }, 2000);
          }
        });

        function scrollToHeading(text) {
          var hs = document.querySelectorAll('.vditor-wysiwyg h1, .vditor-wysiwyg h2, .vditor-wysiwyg h3, .vditor-wysiwyg h4, .vditor-wysiwyg h5, .vditor-wysiwyg h6');
          for (var i = 0; i < hs.length; i++) {
            if (hs[i].textContent.trim() === text) {
              hs[i].scrollIntoView({behavior: 'smooth', block: 'start'});
              hs[i].style.transition = 'background-color 0.5s';
              hs[i].style.backgroundColor = '#3a3a5a';
              setTimeout(function(h) { h.style.backgroundColor = 'transparent'; }, 1200, hs[i]);
              return;
            }
          }
        }
        </script>
        </body>
        </html>
        """
    }

    func loadMD(from url: URL) {
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else {
            let a = NSAlert(); a.messageText = "无法加载 Markdown"; a.informativeText = url.path; a.runModal(); return
        }

        currentURL = url
        fileLabel.stringValue = url.lastPathComponent

        webView.stopLoading()
        let editorID = "editor_\(UUID().uuidString.replacingOccurrences(of: "-", with: "_"))"
        let html = getHTMLTemplate(content: content, editorID: editorID, cacheID: "md:\(url.path)")
        let tmpDir = FileManager.default.temporaryDirectory
        let tmpFile = tmpDir.appendingPathComponent("md_editor_\(UUID().uuidString).html")
        try? html.write(to: tmpFile, atomically: true, encoding: .utf8)
        webView.loadFileURL(tmpFile, allowingReadAccessTo: tmpDir)
    }

    func goTo(item: MDOutlineItem) {
        let jsTitle = item.title
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        let js = "scrollToHeading('\(jsTitle)');"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
}
