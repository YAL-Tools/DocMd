<!-- this is generated from README.dmd! don't edit it by hand -->

<!--<doc--><h1>DocMd (working title?)</span></h1><p>
A Markdown-esque renderer written in Haxe.
</p><p>
As per name, it is primarily used for writing section-based documentation (<a href="https://yal.cc/r/17/gmlive/">example</a>),
although it has since been expanded for use <a href="https://yal.cc/">in my blog posts</a> and various other bits (like my <a href="https://yal.cc/works/">portfolio</a>, or my <i><a href="https://yal.cc/works-ext/">other portfolio</a></i>, or one-off uses).
</p></p>
<!--more--><h2 id="Motivation"><a href="#Motivation" title="(permalink)">Motivation</a></h2><ul>
<li> Lack of support for nested sections in "vanilla" Markdown.
</li><li> Syntactic ambiguities in "vanilla" Markdown. <br/>
  (e.g. mixing lists/tables/code blocks gets nasty quickly and you have to hand-write HTML)
</li><li> Documents that I write often require "one-off" tags to maintain editable source files.
</li></ul></p><h2 id="Features"><a href="#Features" title="(permalink)">Features</a></h2><ul>
<li> Mostly-familiar syntax (see notes below)
</li><li> GML syntax highlighting (complete with cross-links)
</li><li> Supports <a href="https://github.com/HaxeFoundation/hscript">hscript</a> for automation and implementing custom tags on per-document basis.
</li></ul></p><h2 id="Building"><a href="#Building" title="(permalink)">Building</a></h2><pre>
haxe -lib hscript -cp src -neko bin/docmd.n -D hscriptPos -main DocMdSys -dce no
</pre></p><h2 id="Running"><a href="#Running" title="(permalink)">Running</a></h2><pre>
neko docmd.n &lt;input.dmd&gt; &lt;template.html&gt; &lt;output.html&gt; [...options]
</pre><p>
Required arguments: </p><ul>
<li> <code>input</code><br/>
	A path to a file with markdown to render.
</li><li>	<code>template</code><br/>
	The <a href="#HTML-template">template page</a> to insert generated HTML to.
</li><li>	<code>output</code><br/>
	A path to a file to save resulting HTML to.
</li></ul><p>
If the three are named like <code>name.html</code> (input), <code>name.dmd.html</code> (template), <code>name.html</code> (output),
template/output arguments can be omitted.
</p><p>
Supported options: </p><ul>
<li> <code>--linear</code><br/>
	Enables "linear" render mode
(e.g. for blog posts or this README, as opposed to the default nested section mode),
along with related post-fixes.
</li><li> <code>--watch</code><br/>
	Keeps the application running and re-renders the file whenever the source files (or their included dependencies) change.
</li><li> <code>--server &lt;port&gt;</code><br/>
	Same as above, but also opens a <i>very simple</i> web server on specified port.<br/>
	Combine with <code>localhost-live.js</code> userscript to have the in-browser preview update whenever you save the file.
</li><li> <code>--include &lt;path&gt;</code><br/>
	Prepends the markdown by contents of the given file.<br/>
	Good for setting up shared variables/helpers for multiple <code>dmd</code> files.
</li><li> <code>--unindent</code><br/>
	Removes leading spaces from "plaintext" parts of the output.<br/>
	When generating a <code>md</code> file from <code>dmd</code> (like this one!), you'll want this to prevent Markdown renderer from turning indented snippets of HTML into code blocks.
</li><li> <code>--gml-api &lt;path&gt;</code><br/>
	Loads API entries (in <code>fnames</code>-like format) for GML syntax highlighting.
</li><li> <code>--gml-assets &lt;path&gt;</code><br/>
	Loads asset names (read: grabs every single identifier in the file) for GML syntax highlighting.
</li><li> <code>--gml-rx-script &lt;regular expression&gt;</code><br/>
	Specifies a regular expression for determining that an identifier in GML code is a script name
and should be highlighted accordingly.
</li><li> <code>--gml-rx-asset &lt;regular expression&gt;</code><br/>
	Specifies a regular expression for determining that an identifier in GML code is an asset name
and should be highlighted accordingly.
</li><li> <code>--set &lt;name&gt;</code>, <code>--set &lt;name&gt;=&lt;value&gt;</code><br/>
	Fills out <a href="#Template-variables">template variables</a>
(as an alternative to using <code>```set</code> in dmd itself)
</li></ul></p><h2 id="Syntax"><a href="#Syntax" title="(permalink)">Syntax</a></h2><p>
Here, <code>—</code> means no native tag, which can be workarounded with HTML insertion in Markdown, plugins in Markdown renderers that support them, or custom tags and/or variables in DocMd.
</p></th><th><table><tr><th><p>
Tag
</p></th><th><p> Markdown
</p></th><th><p> DMD
</p></th><th><p> Notes on DMD
 </p></th></tr><tr><td>
Line break
</p></td><td><p> 2 spaces before EOL
</p></td><td><p> 2 spaces before EOL <br/>
<i>or</i> <code>\</code> before EOL
</p></td><td></td></tr><tr><td><p> <i>Italic</i>
</p></td><td><p> <code>*text*</code>, <code>_text_</code>
</p></td><td><p> <code>_text_</code>
</p></td><td><p> Doesn't trigger on mid-identifier matches

</p></td></tr><tr><td><p> <b>Bold</b>
</p></td><td><p> <code>**text**</code>, <code>__text__</code>
</p></td><td><p> <code>*text*</code>
</p></td><td></td></tr><tr><td><p> <s>strikethrough</s>
</p></td><td><p> <code>~~text~~</code>
</p></td><td><p> <code>~~text~~</code>
</p></td><td></td></tr><tr><td><h3>Headers</h3></td><td><p> <code># Text</code>,<br/>
<code>## Text</code>,
</p><pre>
Text
------
</pre></td><td><p> <code># Text</code>,<br/>
<code>## Text</code>, etc.
</p></td><td><p> <code># [Text](name)</code> for permalinks;<br/>
<code># [Text]()</code> to auto-create permalink;

</p></td></tr><tr><td><p> <a href="#Syntax">Links</a>
</p></td><td><p> <code>[text](url)</code>
</p></td><td><p> <code>[text](url)</code> <br/>
or <code>[text-url]</code>
</p></td><td><p> Auto-converts URLs not starting with a protocol or a slash into <code>#urls</code>;<br/>
URL➜text generation uses same rules as headers;<br/>
Prepend URL with <code>+</code> for new tab (<code>noreferrer noopener</code>);<br/>
Prepend URL with <code>!</code> to add <code>nofollow</code>;

</p></td></tr><tr><td><p> Ruler
</p><hr/></td><td><pre>
---
***
___
</pre></td><td><pre> ---</pre></td><td></td></tr><tr><td><p> <abbr title="Mouseover text in 'title' attribute">Abbr</abbr>
</p></td><td><p> —
</p></td><td><p> <code>[text](^title)</code>
</p></td><td></td></tr><tr><td><p> <sup>Sup</sup>
</p></td><td><p> —
</p></td><td><p> <code>^(text)</code>, <code>^[text]</code>
</p></td><td><p> <code>^[]</code> doesn't unwrap, so <code>^[1]</code> becomes <sup>[1]</sup> - good for mid-section citations

</p></td></tr><tr><td><p> Images
</p></td><td><p> <code>![alt](url)</code>
</p></td><td><p> <code>![alt](url)</code><br/>
or <code>![url]</code> (no alt-text)
</p></td><td></td></tr><tr><td><p> <ul><li>Unordered list</li></ul>
</p></td><td><pre>
- one
* two (alt.)
</pre></td><td><pre>
--{
- one
-- two (alt.)
}
</pre></td><td><p> Closing <code>}</code> may also be preceded by <code>--</code>

</p></td></tr><tr><td><p> <ol><li>Ordered list</li></ol>
</p></td><td><pre>
1. one
2. two
</pre></td><td><pre>
##{
- one
-- two (alt.)
}
</pre></td><td><p> Not well thought-out - rarely used.

</p></td></tr><tr><td><p> <blockquote>blockquote</blockquote>
</p></td><td><pre>
&gt; text
</pre></td><td><pre>
```quote
plaintext
```
```quotemd
markdown
```
</pre></td><td><p> Not used often either.

</p></td></tr><tr><td><pre> code</pre></td><td><pre>
```
code
```
```kind
code
```
    code (indented)
</pre></td><td><pre>
```
code
```
```kind
code
```
```kind code```
</pre></td><td><p> If code block is the first thing at a line, unindents and matches the closing tag with same indentation, meaning that you can do
</p><pre>
Code example:
```
	```
	code
	```
```
</pre><p>
More on supported blocks later
 </p></td></tr></table></p><h3 id="HTML-inserts"><a href="#HTML-inserts" title="(permalink)">HTML inserts</a></h3><p>
DocMd doesn't automatically process HTML tags (with exception of <code>&lt;!--comments--&gt;</code>),
but you may use <code>${}</code> or
</p><pre>
```raw
HTML code here
```
</pre><p>
to inject HTML.
</p></p><h2 id="Code-blocks"><a href="#Code-blocks" title="(permalink)">Code blocks</a></h2><p>
DocMd supports a number of code block types out of box: </p><ul>
<li><p> <code>raw</code><br/>
	Injects HTML as-is, as per above.<br/>
	Note that this will not auto-close paragraphs/etc.
</p><pre>
```raw
&lt;b&gt;hello&lt;/b&gt;
```
</pre><p>
➜
 <b>hello</b> 
</p></li><li><p> <code>quote</code><br/>
	Inserts a plaintext blockquote,
</p><pre>
```quote
This is *plaintext*
```
</pre><p>
➜
<blockquote>
	This is *plaintext*
</blockquote>
</p></li><li><p> <code>quotemd</code><br/>
	Like above, but will process markdown in it
</p><pre>
```quotemd
This is *markdown*
```
</pre><p>
➜
<blockquote>
This is <b>markdown</b>
</blockquote>
</p></li><li><p> <code>exec</code><br/>
	Executes an hscript code snippet.
</p><p>
If the code returns a non-<b>null</b> value, it will be appended to output as HTML (see <a href="#hscript-API">hscript API</a>).
</p><pre>
```exec
return "&lt;b&gt;" + ["hello", "there"].join(" ") + "&lt;/b&gt;";
```
</pre><p>
➜
<b>hello there</b>
</p></li><li><p> <code>codecss</code><br/>
	Adds the given CSS to the next code block's <code>style</code> attribute - e.g.
</p><pre>
```codecss
height: 35%;
height: 35vh;
```
```
this code block will take up 35% of browser height
```
</pre></li><li> <code>hide</code><br/>
	Doesn't output <i>anything</i>.
</li><li> <code>set</code>, <code>setmd</code><br/>
	Sets <a href="#Template-variables">template variables</a>.
</li><li> <code>gml</code><br/>
	Pretty reasonable syntax highlighting for GameMaker Language (GML). Has a bunch of tweaks (see below)
</li><li> <code>lua</code><br/>
	Less-reasonable syntax highlighting for Lua that's hacked on top of above.
</li></ul><p>
GML-related tags:
</p><ul>
<li><p> <code>gmlapi</code><br/>
	Processes <code>fnames</code>-like entries for GML highlighting, similar to the <code>--gml-api</code> option - e.g.
</p><pre>
```gmlapi
a_function()
a_variable
a_constant#
```
</pre></li><li><p> <code>gmlassets</code><br/>
	Adds asset names for GML highlighting, similar to the <code>--gml-assets</code> option - e.g.
</p><pre>
```gmlassets
objPlayer objController
```
</pre></li><li><p> <code>gmlkeywords</code><br/>
	Adds keywords for GML highlighting - e.g.
</p><pre>
```gmlkeywords
select option
```
</pre><p>
This is mostly handy if you are using <code>gml</code> tag to highlight something that isn't <i>really</i> GML code (such as Tiny Expression's Runtime documentation does).
</p></li><li><p> <code>gmlhint</code><br/>
	The given snippet of GML code (containing <code>#define</code>s and variable declarations) will be used
when highlighting the next <code>gml</code> block.
</p><p>
This is handy for cases when a piece of code is being shown "out of context"
(or you are interrupting it halfway through with an explanation of what's going on)
but you still want consistent syntax highlighting.
</p></li></ul></p><h2 id="Template-variables"><a href="#Template-variables" title="(permalink)">Template variables</a></h2><p>
DocMd has a template variable system for reusing snippets of text, inserting contents of other
files, and alike.
</p><pre>
```set toolname DocMd```
%[toolname] is a Markdown-esque renderer.
</pre><p>➜

DocMd is a Markdown-esque renderer.
</p><p>
You can also load template variables from files,
</p><pre>
```set intro ./intro.dmd```
%[intro]
</pre><p>
Variables can be also accessed through hscript and used to manipulate generated code (see below).
</p><p>
The following variables have special purpose: </p><ul>
<li> <code>template</code>: allows setting page template in the page itself.
</li><li> <code>tag:defcode</code>: changes how code blocks without a "type" will be processed (e.g. setting this to <code>gml</code> will process them as GML snippets by default).
</li></ul></p><h2 id="HTML-template"><a href="#HTML-template" title="(permalink)">HTML template</a></h2><p>
This file will be used as a template for resulting HTML (or HTML-containing) file.
</p><p>
At the very least, your file should contain
</p><pre>
&lt;!--&lt;doc--&gt;&lt;!--doc&gt;--&gt;
</pre><p>
that the generated code will be inserted between,
but you may also utilize conditional comments to customize the output or include/exclude parts of it
depending on the input:
</p><ul>
<li><p> <code>&lt;!--%[variable]--&gt;</code><br/>
	Will be replaced by contents of the given <a href="#Template-variables">template variable</a> - e.g.
</p><pre>```set title cool document```</pre><p>
and then in the template:
</p><pre>
&lt;title&gt;&lt;!--%[title]--&gt;&lt;/title&gt;
</pre></li><li><p> <code>&lt;!--%[if variable]--&gt;</code> .. [<code>&lt;!--%[else]--&gt;</code>] .. <code>&lt;!--%[endif]--&gt;</code><br/>
	Conditional processing for template variables.
</p><p>
Currently very simple - just <code>variable</code> and <code>!variable</code> really.
Perhaps another use case for hscript.
</p></li><li> <code>&lt;!--include relPath--&gt;</code>, <code>/*include relPath*/</code><br/>
	Will be replaced by the contents of specified file.<br/>
	Useful for generating single-page outputs while keeping the source readable!
</li></ul></p><h2 id="default-template"><a href="#default-template" title="(permalink)">default.html</a></h2><p>
This is the template that I use for my documentation.
</p><p>
It supports the following template variables:
</p><ul>
<li> <code>title</code>: page and OpenGraph title.
</li><li> <code>intro</code>: shown above page controls.
</li><li> <code>theme-color</code>: <a href="https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meta/name/theme-color">theme-color</a> meta - used for various accents in browsers and embeds.
</li><li> <code>og:url</code>: an <i>absolute</i> URL to the page for OpenGraph.
</li><li> <code>og:desc</code>: an excerpt for OpenGraph - shown in embeds.
</li><li> <code>og:image</code>: an <i>absolute</i> URL to the image for OpenGraph. Usually 16:9 or so.
</li><li> <code>og:image:width</code>: width of above, in pixels.
</li><li> <code>og:image:height</code>: height of above, in pixels.
</li></ul></p><h2 id="hscript-API"><a href="#hscript-API" title="(permalink)">hscript API</a></h2><ul>
<li><p> <code>global</code><br/>
	A reference to this same global scope, in case you need it.
</p></li><li><p> <code>print(...values)</code><br/>
	Appends one or more values to output. If the snippet also returns a value, it will be appended afterwards.
</p></li><li><p> <code>render(dmd:String)-&gt;String</code><br/>
	Processes the given DocMd snippet and returns the resulting HTML.
</p></li><li><p> <code>include(path:String)-&gt;String</code><br/>
	Reads a file from a relative path, processes it, and returns the resulting HTML.
</p></li><li><p> <code>sfmt(format:String, ...values)-&gt;String</code><br/>
	A simple helper that replaces <code>%</code>s in a format string by respective values
(e.g. <code>sfmt("%/%", 1, 2)</code> returns <code>"1/2"</code>).
</p></li><li><p> <code>DocMd.makeID(text:String)-&gt;String</code><br/>
	Converts a text string into a valid #id (e.g. <code>section 2</code> ➜ <code>section-2</code>) using the same rules as the headers/links do.
</p></li><li><p> <code>DocMd.addCodeTag(name:String, handler:String-&gt;Any)</code><br/>
	Registers a new code block handler. The handler receives the snippet inside the block and should return the resulting HTML. For example, you could do
</p><pre>
```exec
DocMd.addCodeTag("center", function(code) {
	return '&lt;div style="text-align: center"&gt;' + render(code) + '&lt;/div&gt;';
});
```
```center
hello!
```
</pre><p>
to have a shorthand for centered text.
</p></li><li><p> <code>DocMd.templateVars:Map&lt;String, String&gt;</code><br/>
	A map containing the collected template variables.
</p></li><li><p> <code>StringBufExt</code><br/>
	An extension of <code>StringBuf</code> that adds <code>addFormat(format:String, ...values)</code> with same logic as <code>sfmt</code>.
</p></li><li><p> <code>File.getContent(path:String)-&gt;String</code><br/>
	Grabs file content as text from specified file.
</p></li><li> <code>File.awaitChanges(path:String)</code><br/>
	When in <code>watch</code> or <code>server</code> mode, will watch for changes to specified path.
</li></ul><p>
See exposed standard library items (Std, Math, StringTools, Reflect, etc.) or add your own in <code>src/dmd/tags/TagExecAPI.hx</code>).
</p><hr/><p>
(...is that all?)</p><!--doc>-->