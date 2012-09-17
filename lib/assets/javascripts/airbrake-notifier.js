var Hoptoad = {
  VERSION           : '0.1.0',
  NOTICE_XML        : '<?xml version="1.0" encoding="UTF-8"?><notice version="2.0"><api-key></api-key><notifier><name>airbrake_js</name><version>0.1.0</version><url>http://airbrake.io</url></notifier><error><class>EXCEPTION_CLASS</class><message>EXCEPTION_MESSAGE</message><backtrace>BACKTRACE_LINES</backtrace></error><request><url>REQUEST_URL</url><component>REQUEST_COMPONENT</component><action>REQUEST_ACTION</action></request><server-environment><project-root>PROJECT_ROOT</project-root><environment-name>production</environment-name></server-environment></notice>',
  ROOT              : window.location.protocol + '//' + window.location.host,
  BACKTRACE_MATCHER : /^(.*)\@(.*)\:(\d+)$/,
  backtrace_filters : [/notifier\.js/],

  notify: function(error) {
    var xml     = escape(Hoptoad.generateXML(error));
    var host    = Hoptoad.host || 'airbrake.io';
    var url     = '//' + host + '/notifier_api/v2/notices?data=' + xml;
    var request = document.createElement('iframe');

    request.style.width   = '1px';
    request.style.height  = '1px';
    request.style.display = 'none';
    request.src = url;

    document.getElementsByTagName('head')[0].appendChild(request);
  },

  setEnvironment: function(value) {
    var matcher = /<environment-name>.*<\/environment-name>/;

    Hoptoad.NOTICE_XML  = Hoptoad.NOTICE_XML.replace(matcher,
                                                     '<environment-name>' +
                                                       value +
                                                     '</environment-name>')
  },

  setHost: function(value) {
    Hoptoad.host = value;
  },

  setKey: function(value) {
    var matcher = /<api-key>.*<\/api-key>/;

    Hoptoad.NOTICE_XML = Hoptoad.NOTICE_XML.replace(matcher,
                                                    '<api-key>' +
                                                      value +
                                                    '</api-key>');
  },

  setErrorDefaults: function(value) {
    Hoptoad.errorDefaults = value;
  },

  generateXML: function(errorWithoutDefaults) {
    var error = Hoptoad.mergeDefault(Hoptoad.errorDefaults, errorWithoutDefaults);

    var xml       = Hoptoad.NOTICE_XML;
    var baseUrl   = error.url     || '';
    var hash      = location.hash || '';
    var url       = Hoptoad.escapeText((baseUrl + hash) || '');
    var component = Hoptoad.escapeText(error.component  || '');
    var action    = Hoptoad.escapeText(error.action     || '');
    var errorType = Hoptoad.escapeText(error.type       || 'Error');
    var message   = Hoptoad.escapeText(error.message    || 'Unknown error.');
    var backtrace = Hoptoad.generateBacktrace(error);


    if (Hoptoad.trim(url) == '' && Hoptoad.trim(component) == '') {
      xml = xml.replace(/<request>.*<\/request>/, '');
    } else {
      var data    = '';

      var cgi_data = error['cgi-data'] || {};
      cgi_data["HTTP_USER_AGENT"] = navigator.userAgent;
      data += '<cgi-data>';
      data += Hoptoad.generateVariables(cgi_data);
      data += '</cgi-data>';

      var methods = ['params', 'session'];

      for (var i = 0; i < 2; i++) {
        var type = methods[i];

        if (error[type]) {
          data += '<' + type + '>';
          data += Hoptoad.generateVariables(error[type]);
          data += '</' + type + '>';
        }
      }

      xml = xml.replace('</request>',        data + '</request>')
               .replace('REQUEST_URL',       url)
               .replace('REQUEST_ACTION',    action)
               .replace('REQUEST_COMPONENT', component);
    }

    return xml.replace('PROJECT_ROOT',      Hoptoad.ROOT)
              .replace('EXCEPTION_CLASS',   errorType)
              .replace('EXCEPTION_MESSAGE', message)
              .replace('BACKTRACE_LINES',   backtrace.join(''));
  },

  generateBacktrace: function(error) {
    error = error || {};

    if (typeof error.stack != 'string') {
      try {
        (0)();
      } catch(e) {
        error.stack = e.stack;
      }
    }

    var backtrace  = [];
    var stacktrace = Hoptoad.getStackTrace(error);

    for (var i = 0, l = stacktrace.length; i < l; i++) {
      var line    = stacktrace[i];
      var matches = line.match(Hoptoad.BACKTRACE_MATCHER);

      if (matches && Hoptoad.validBacktraceLine(line)) {
        var file = matches[2].replace(Hoptoad.ROOT, '[PROJECT_ROOT]');

        if (i == 0) {
          if (matches[2].match(document.location.href)) {
            backtrace.push('<line method="" file="internal: " number=""/>');
          }
        }

        backtrace.push('<line method="' + Hoptoad.escapeText(matches[1]) +
                       '" file="' + Hoptoad.escapeText(file) +
                       '" number="' + matches[3] + '" />');
      }
    }

    return backtrace;
  },

  getStackTrace: function(error) {
    var stacktrace = printStackTrace({ e : error, guess : false });

    for (var i = 0, l = stacktrace.length; i < l; i++) {
      if (stacktrace[i].match(/\:\d+$/)) {
        continue;
      }

      if (stacktrace[i].indexOf('@') == -1) {
        stacktrace[i] += '@unsupported.js';
      }

      stacktrace[i] += ':0';
    }

    return stacktrace;
  },

  validBacktraceLine: function(line) {
    for (var i = 0; i < Hoptoad.backtrace_filters.length; i++) {
      if (line.match(Hoptoad.backtrace_filters[i])) {
        return false;
      }
    }

    return true;
  },

  generateVariables: function(parameters) {
    var key;
    var result = '';

    for (key in parameters) {
      result += '<var key="' + Hoptoad.escapeText(key) + '">' +
                  Hoptoad.escapeText(parameters[key]) +
                '</var>';
    }

    return result;
  },

  escapeText: function(text) {
    return text.replace(/&/g, '&#38;')
               .replace(/</g, '&#60;')
               .replace(/>/g, '&#62;')
               .replace(/'/g, '&#39;')
               .replace(/"/g, '&#34;');
  },

  trim: function(text) {
    return text.toString().replace(/^\s+/, '').replace(/\s+$/, '');
  },

  mergeDefault: function(defaults, hash) {
    var cloned = {};
    var key;

    for (key in hash) {
      cloned[key] = hash[key];
    }

    for (key in defaults) {
      if (!cloned.hasOwnProperty(key)) {
        cloned[key] = defaults[key];
      }
    }

    return cloned;
  }
};




// Domain Public by Eric Wendelin http://eriwen.com/ (2008)
//                  Luke Smith http://lucassmith.name/ (2008)
//                  Loic Dachary <loic@dachary.org> (2008)
//                  Johan Euphrosine <proppy@aminche.com> (2008)
//                  Øyvind Sean Kinsey http://kinsey.no/blog (2010)
//                  Victor Homyakov <victor-homyakov@users.sourceforge.net> (2010)
//
// Information and discussions
// http://jspoker.pokersource.info/skin/test-printstacktrace.html
// http://eriwen.com/javascript/js-stack-trace/
// http://eriwen.com/javascript/stacktrace-update/
// http://pastie.org/253058
//
// guessFunctionNameFromLines comes from firebug
//
// Software License Agreement (BSD License)
//
// Copyright (c) 2007, Parakey Inc.
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above
//   copyright notice, this list of conditions and the
//   following disclaimer.
//
// * Redistributions in binary form must reproduce the above
//   copyright notice, this list of conditions and the
//   following disclaimer in the documentation and/or other
//   materials provided with the distribution.
//
// * Neither the name of Parakey Inc. nor the names of its
//   contributors may be used to endorse or promote products
//   derived from this software without specific prior
//   written permission of Parakey Inc.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
// FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
// IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
function printStackTrace(a){var a=a||{guess:!0},b=a.e||null,a=!!a.guess,c=new printStackTrace.implementation,b=c.run(b);return a?c.guessFunctions(b):b}printStackTrace.implementation=function(){};
printStackTrace.implementation.prototype={run:function(a){var a=a||this.createException(),b=this.mode(a);return b==="other"?this.other(arguments.callee):this[b](a)},createException:function(){try{return this.undef(),null}catch(a){return a}},mode:function(a){if(a.arguments&&a.stack)return this._mode="chrome";else if(typeof window!=="undefined"&&window.opera)return this._mode=a.stacktrace?"opera10":"opera";else if(a.stack)return this._mode="firefox";return this._mode="other"},instrumentFunction:function(a,
b,c){a=a||window;a["_old"+b]=a[b];a[b]=function(){c.call(this,printStackTrace());return a["_old"+b].apply(this,arguments)};a[b]._instrumented=!0},deinstrumentFunction:function(a,b){a[b].constructor===Function&&a[b]._instrumented&&a["_old"+b].constructor===Function&&(a[b]=a["_old"+b])},chrome:function(a){return a.stack.replace(/^[^\(]+?[\n$]/gm,"").replace(/^\s+at\s+/gm,"").replace(/^Object.<anonymous>\s*\(/gm,"{anonymous}()@").split("\n")},firefox:function(a){return a.stack.replace(/(?:\n@:0)?\s+$/m,
"").replace(/^\(/gm,"{anonymous}(").split("\n")},opera10:function(a){var a=a.stacktrace.split("\n"),b=/.*line (\d+), column (\d+) in ((<anonymous function\:?\s*(\S+))|([^\(]+)\([^\)]*\))(?: in )?(.*)\s*$/i,c,d,e;c=2;d=0;for(e=a.length;c<e-2;c++)if(b.test(a[c])){var g=RegExp.$6+":"+RegExp.$1+":"+RegExp.$2,f=RegExp.$3,f=f.replace(/<anonymous function\:?\s?(\S+)?>/g,"{anonymous}");a[d++]=f+"@"+g}a.splice(d,a.length-d);return a},opera:function(a){var a=a.message.split("\n"),b=/Line\s+(\d+).*script\s+(http\S+)(?:.*in\s+function\s+(\S+))?/i,
c,d,e;c=4;d=0;for(e=a.length;c<e;c+=2)b.test(a[c])&&(a[d++]=(RegExp.$3?RegExp.$3+"()@"+RegExp.$2+RegExp.$1:"{anonymous}()@"+RegExp.$2+":"+RegExp.$1)+" -- "+a[c+1].replace(/^\s+/,""));a.splice(d,a.length-d);return a},other:function(a){for(var b=/function\s*([\w\-$]+)?\s*\(/i,c=[],d,e;a&&c.length<10;)d=b.test(a.toString())?RegExp.$1||"{anonymous}":"{anonymous}",e=Array.prototype.slice.call(a.arguments||[]),c[c.length]=d+"("+this.stringifyArguments(e)+")",a=a.caller;return c},stringifyArguments:function(a){for(var b=
0;b<a.length;++b){var c=a[b];c===void 0?a[b]="undefined":c===null?a[b]="null":c.constructor&&(c.constructor===Array?a[b]=c.length<3?"["+this.stringifyArguments(c)+"]":"["+this.stringifyArguments(Array.prototype.slice.call(c,0,1))+"..."+this.stringifyArguments(Array.prototype.slice.call(c,-1))+"]":c.constructor===Object?a[b]="#object":c.constructor===Function?a[b]="#function":c.constructor===String&&(a[b]='"'+c+'"'))}return a.join(",")},sourceCache:{},ajax:function(a){var b=this.createXMLHTTPObject();
if(b)return b.open("GET",a,!1),b.setRequestHeader("User-Agent","XMLHTTP/1.0"),b.send(""),b.responseText},createXMLHTTPObject:function(){for(var a,b=[function(){return new XMLHttpRequest},function(){return new ActiveXObject("Msxml2.XMLHTTP")},function(){return new ActiveXObject("Msxml3.XMLHTTP")},function(){return new ActiveXObject("Microsoft.XMLHTTP")}],c=0;c<b.length;c++)try{return a=b[c](),this.createXMLHTTPObject=b[c],a}catch(d){}},isSameDomain:function(a){return a.indexOf(location.hostname)!==
-1},getSource:function(a){a in this.sourceCache||(this.sourceCache[a]=this.ajax(a).split("\n"));return this.sourceCache[a]},guessFunctions:function(a){for(var b=0;b<a.length;++b){var c=a[b],d=/\{anonymous\}\(.*\)@(\w+:\/\/([\-\w\.]+)+(:\d+)?[^:]+):(\d+):?(\d+)?/.exec(c);if(d){var e=d[1],d=d[4];e&&this.isSameDomain(e)&&d&&(e=this.guessFunctionName(e,d),a[b]=c.replace("{anonymous}",e))}}return a},guessFunctionName:function(a,b){var c;try{c=this.guessFunctionNameFromLines(b,this.getSource(a))}catch(d){c=
"getSource failed with url: "+a+", exception: "+d.toString()}return c},guessFunctionNameFromLines:function(a,b){for(var c=/function ([^(]*)\(([^)]*)\)/,d=/['"]?([0-9A-Za-z_]+)['"]?\s*[:=]\s*(function|eval|new Function)/,e="",g=0;g<10;++g)if(e=b[a-g]+e,e!==void 0){var f=d.exec(e);if(f&&f[1])return f[1];else if((f=c.exec(e))&&f[1])return f[1]}return"(?)"}};




window.onerror = function(message, file, line) {
  setTimeout(function() {
    Hoptoad.notify({
      message : message,
      stack   : '()@' + file + ':' + line
    });
  }, 100);
  return true;
};
