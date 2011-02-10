// xAddClass, Copyright 2005-2007 Daniel Frechette
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

/**
 * @param e - Str/Obj - Element id or object
 * @param c - Str     - Class name
 * @return Bool - true successful, false otherwise
 */
function xAddClass(e, c) {
  e = xGetElementById(e);
  if (!e)
    return false;
  if (!xHasClass(e, c))
    e.className += ' '+c;
  return true;
};
// xAddEventListener2, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xAddEventListener2(e,eT,eL,cap) // original implementation
{
  if(!(e=xGetElementById(e))) return;
  eT=eT.toLowerCase();
  if (e==window && !e.opera && !document.all) { // simulate resize and scroll events for all except Opera and IE
    if(eT=='resize') { e.xPCW=xClientWidth(); e.xPCH=xClientHeight(); e.xREL=eL; xResizeEvent(); return; }
    if(eT=='scroll') { e.xPSL=xScrollLeft(); e.xPST=xScrollTop(); e.xSEL=eL; xScrollEvent(); return; }
  }
  if(e.addEventListener) e.addEventListener(eT,eL,cap||false);
  else if(e.attachEvent) e.attachEvent('on'+eT,eL);
  else e['on'+eT]=eL;
}
// called only from the above
function xResizeEvent()
{
  if (window.xREL) setTimeout('xResizeEvent()', 250);
  var w=window, cw=xClientWidth(), ch=xClientHeight();
  if (w.xPCW != cw || w.xPCH != ch) { w.xPCW = cw; w.xPCH = ch; if (w.xREL) w.xREL(); }
}
function xScrollEvent()
{
  if (window.xSEL) setTimeout('xScrollEvent()', 250);
  var w=window, sl=xScrollLeft(), st=xScrollTop();
  if (w.xPSL != sl || w.xPST != st) { w.xPSL = sl; w.xPST = st; if (w.xSEL) w.xSEL(); }
}
// xAddEventListener3, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Modified by Ivan Pepelnjak, 11Nov06
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xAddEventListener3(e,eT,eL,cap)
{
  if(!(e=xGetElementById(e))) return;
  eT=eT.toLowerCase();
  if (e==window && !e.opera && !document.all) { // simulate resize and scroll events for all except Opera and IE
    if(eT=='resize') {
      e.xPCW=xClientWidth(); e.xPCH=xClientHeight();
      var pREL = e.xREL ;
      e.xREL= pREL ? function() { eL(); pREL(); } : eL;
      xResizeEvent(); return;
    }
    if(eT=='scroll') {
      e.xPSL=xScrollLeft(); e.xPST=xScrollTop();
      var pSEL = e.xSEL ;
      e.xSEL=pSEL ? function() { eL(); pSEL(); } : eL;
      xScrollEvent(); return; }
  }
  if(e.addEventListener) e.addEventListener(eT,eL,cap);
  else if(e.attachEvent) e.attachEvent('on'+eT,eL);
  else {
    var pev = e['on'+eT] ;
    e['on'+eT]= pev ? function() { eL(); typeof(pev) == 'string' ? eval(pev) : pev(); } : eL ;
  }
}
// called only from the above
function xResizeEvent()
{
  if (window.xREL) setTimeout('xResizeEvent()', 250);
  var w=window, cw=xClientWidth(), ch=xClientHeight();
  if (w.xPCW != cw || w.xPCH != ch) { w.xPCW = cw; w.xPCH = ch; if (w.xREL) w.xREL(); }
}
function xScrollEvent()
{
  if (window.xSEL) setTimeout('xScrollEvent()', 250);
  var w=window, sl=xScrollLeft(), st=xScrollTop();
  if (w.xPSL != sl || w.xPST != st) { w.xPSL = sl; w.xPST = st; if (w.xSEL) w.xSEL(); }
}
// xAddEventListener, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xAddEventListener(e,eT,eL,cap)
{
  if(!(e=xGetElementById(e)))return;
  eT=eT.toLowerCase();
  if(e.addEventListener)e.addEventListener(eT,eL,cap||false);
  else if(e.attachEvent)e.attachEvent('on'+eT,eL);
  else e['on'+eT]=eL;
}
// xAniEllipse, Copyright 2006-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xAniEllipse(xa, xr, yr, a1, a2, tt, at, qc, oed, oea, oef)
{
  var a = xa.init(xa.e, at, qc, tt, onRun, onRun, oed, oea, oef);
  a.x1 = a1 * (Math.PI / 180); // start angle
  a.x2 = a2 * (Math.PI / 180); // end angle
  var sx = xLeft(a.e) + (xWidth(a.e) / 2); // start point
  var sy = xTop(a.e) + (xHeight(a.e) / 2);
  a.xc = sx - (xr * Math.cos(a.x1)); // arc center point
  a.yc = sy - (yr * Math.sin(a.x1));
  a.xr = xr; // radii
  a.yr = yr;
  if (a.as) a.start();
  return a;
  function onRun(o) {
    xMoveTo(o.e,
      Math.round(o.xr * Math.cos(o.x)) + o.xc - (xWidth(o.e) / 2),
      Math.round(o.yr * Math.sin(o.x)) + o.yc - (xHeight(o.e) / 2));
  }
}
// xAniLine, Copyright 2006-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xAniLine(xa, x, y, tt, at, qc, oed, oea, oef)
{
  var a = xa.init(xa.e, at, qc, tt, onRun, onRun, oed, oea, oef);
  a.x1 = xLeft(a.e); // start point
  a.y1 = xTop(a.e);
  a.x2 = x; // end point
  a.y2 = y;
  if (a.as) a.start();
  return a;
  function onRun(o) { xMoveTo(o.e, Math.round(o.x), Math.round(o.y)); }
}
// xAnimation, Copyright 2006-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

/* This needs much more testing. mf, 25Sep06 */

/*
Other properties of xAnimation:
  x,y // instantaneous point
  af // acceleration factor
  ap // acceleration period
  t1 // start time
  et // elapsed time
  tmr // timer handle
  x1,y1 // start point or angle
  x2,y2 // end point or angle
  xm,ym // component magnitudes or arc length
  as // auto-start
Other properties used only by callbacks:
 xEllipse:
  xr,yr // x and y radii
  xc,yc // arc center point
 xSlideCorner:
  corner // corner string
 xParaEq:
  xs,ys // expression strings
  inc // T increment
*/

function xAnimation(e, at, qc, tt, orf, otf, oed, oea, oef) // Object Prototype
{
  this.init(e, at, qc, tt, orf, otf, oed, oea, oef);
  var a = xAnimation.instances;
  var i;
  for (i = 0; i < a.length; ++i) { if (!a[i]) break; } // find an empty slot
  a[i] = this;
  this.idx = i;
}

xAnimation.instances = []; // static property

xAnimation.prototype.init = function(e, at, qc, tt, orf, otf, oed, oea, oef)
{
  this.e = xGetElementById(e); // e is object ref or id str
  this.at = at || 2; // acceleration type: 1=linear, 2=sine, 3=cosine
  this.qc = qc || 1; // acceleration quarter-cycles
  this.tt = tt; // total time
  this.orf = orf; // onRun function
  this.otf = otf; // onTarget function
  this.oed = oed; // delay before calling onEnd
  this.oea = oea; // onEnd argument
  this.oef = oef; // onEnd function
  this.to = 20; // timer timeout
  this.as = true; // auto-start
  return this;
};

xAnimation.prototype.start = function()
{
  var a = this;
  // acceleration
  if (a.at == 1) { a.ap = 1 / a.tt; } // linear
  else { a.ap = a.qc * (Math.PI / (2 * a.tt)); } // sine and cosine
  // magnitudes
  if (xDef(a.x1)) { a.xm = a.x2 - a.x1; }
  if (xDef(a.y1)) { a.ym = a.y2 - a.y1; }
  // end point if even number of cyles
  if (!(a.qc % 2)) {
    if (xDef(a.x1)) a.x2 = a.x1;
    if (xDef(a.y1)) a.y2 = a.y1;
  }
  if (!a.tmr) { // if not already running
    var d = new Date();
    a.t1 = d.getTime(); // start time
    a.tmr = setTimeout('xAnimation.run(' + a.idx + ')', 1);
  }
};

xAnimation.run = function(i) // static method
{
  var a = xAnimation.instances[i];
  if (!a) { /*alert('invalid index');*/ return; }
  var d = new Date();
  a.et = d.getTime() - a.t1; // elapsed time
  if (a.et < a.tt) {
    a.tmr = setTimeout('xAnimation.run(' + i + ')', a.to);
    // acceleration
    a.af = a.ap * a.et;  // linear
    if (a.at == 2) { a.af = Math.abs(Math.sin(a.af)); } // sine
    else if (a.at == 3) { a.af = 1 - Math.abs(Math.cos(a.af)); } // cosine
    // instantaneous point
    if (xDef(a.x1)) a.x = a.xm * a.af + a.x1;
    if (xDef(a.y1)) a.y = a.ym * a.af + a.y1;
    a.orf(a); // onRun
  }
  else {
    var rep = false; // repeat
    if (xDef(a.x2)) a.x = a.x2;
    if (xDef(a.y2)) a.y = a.y2;
    a.tmr = null;
    a.otf(a); // onTarget
    if (xDef(a.oef)) { // onEnd
      if (a.oed) setTimeout(a.oef, a.oed); // no args passed to oef if oed or oef is str
      else if (xStr(a.oef)) { rep = eval(a.oef); }
      else { rep = a.oef(a, a.oea); }
    }
    if (rep) { a.resume(true); } // there may be a problem here if the anim is paused and oef returns true
/*
    if (rep && a.tmr) {
      a.tmr = null;
      a.resume(true);
    }
    else a.tmr = null;
*/
  }
};

xAnimation.prototype.pause = function()
{
  var s = false;
  if (this.tmr) {
    clearTimeout(this.tmr);
    this.tmr = null;
    s = true;
  }
  return s;
};

xAnimation.prototype.resume = function(fromStart)
{
  var s = false;
  if (!this.tmr) {
    var d = new Date();
    this.t1 = d.getTime();
    if (!fromStart) this.t1 -= this.et; // new start time is current time minus elapsed time
    this.tmr = setTimeout('xAnimation.run(' + this.idx + ')', this.to);
    s = true;
  }
  return s;
};

xAnimation.prototype.kill = function()
{
  this.pause();
  xAnimation.instances[this.idx] = null;
};

// end xAnimation
// xAniOpacity, Copyright 2006-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

// xAniOpacity - Animate an element's opacity.

function xAniOpacity(xa, o, tt, at, qc, oed, oea, oef)
{
  var a = xa.init(xa.e, at, qc, tt, onRun, onRun, oed, oea, oef);
  a.x1 = xOpacity(a.e); // start opacity
  a.x2 = o; // end opacity
  if (a.as) a.start();
  return a;
  function onRun(o) { xOpacity(o.e, o.x); }
  // (o.x == 1) ? 0.9999 : o.x; // for Gecko bug?
}
// xAniScroll, Copyright 2006-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xAniScroll(xa, x, y, tt, at, oed, oea, oef)
{
  var a = xa.init(xa.e, at, 1, tt, onRun, onRun, oed, oea, oef);
  a.x1 = xScrollLeft(a.e, 1); // start point
  a.y1 = xScrollTop(a.e, 1);
  a.x2 = x; // end point
  a.y2 = y;
  if (a.as && a.e.scrollTo) a.start();
  //else alert('scrollTo not supported');
  return a;
  function onRun(o) { o.e.scrollTo(Math.round(o.x), Math.round(o.y)); }
}
// xAniSize, Copyright 2006-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xAniSize(xa, w, h, tt, at, qc, oed, oea, oef)
{
  var a = xa.init(xa.e, at, qc, tt, onRun, onRun, oed, oea, oef);
  a.x1 = xWidth(a.e); // start size
  a.y1 = xHeight(a.e);
  a.x2 = w; // end size
  a.y2 = h;
  if (a.as) a.start();
  return a;
  function onRun(o) { xResizeTo(o.e, Math.round(o.x), Math.round(o.y)); }
}
// xAppendChild, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xAppendChild(oParent, oChild)
{
  if (oParent.appendChild) return oParent.appendChild(oChild);
  else return null;
}
// xBackground, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xBackground(e,c,i)
{
  if(!(e=xGetElementById(e))) return '';
  var bg='';
  if(e.style) {
    if(xStr(c)) {e.style.backgroundColor=c;}
    if(xStr(i)) {e.style.backgroundImage=(i!='')? 'url('+i+')' : null;}
    bg=e.style.backgroundColor;
  }
  return bg;
}
// xBar, Copyright 2003-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

// Bar-Graph Object

function xBar(dir,                // direction, 'ltr', 'rtl', 'ttb', or 'btt'
              conStyle, barStyle) // container and bar style class names
{
  //// Public Properties

  this.value = 0; // current value, read-only

  //// Public Methods

  // Update current value
  this.update = function(v)
  {
    if (v < 0) v = 0;
    else if (v > this.inMax) v = this.inMax;
    this.con.title = this.bar.title = this.value = v;
    switch(this.dir) {
      case 'ltr': // left to right
      v = this.scale(v, this.w);
      xLeft(this.bar, v - this.w);
      break;
      case 'rtl': // right to left
      v = this.scale(v, this.w);
      xLeft(this.bar, this.w - v);
      break;
      case 'btt': // bottom to top
      v = this.scale(v, this.h);
      xTop(this.bar, this.h - v);
      break;
      case 'ttb': // top to bottom
      v = this.scale(v, this.h);
      xTop(this.bar, v - this.h);
      break;
    }
  };

  // Change position and/or size
  this.paint = function(x, y, // container position
                        w, h) // container size
  {
    if (xNum(x)) this.x = x;
    if (xNum(y)) this.y = y;
    if (xNum(w)) this.w = w;
    if (xNum(h)) this.h = h;
    xResizeTo(this.con, this.w, this.h);
    xMoveTo(this.con, this.x, this.y);
    xResizeTo(this.bar, this.w, this.h);
    xMoveTo(this.bar, 0, 0);
  };

  // Change scale and/or start value
  this.reset = function(max, start) // non-scaled values
  {
    if (xNum(max)) this.inMax = max;
    if (xNum(start)) this.start = start;
    this.update(this.start);
  };

  //// Private Methods
  
  this.scale = function(v, outMax)
  {
    return Math.round(xLinearScale(v, 0, this.inMax, 0, outMax));
  };

  //// Private Properties

  this.dir = dir;
  this.x = 0;
  this.y = 0;
  this.w = 100;
  this.h = 100;
  this.inMax = 100;
  this.start = 0;
  this.conStyle = conStyle;
  this.barStyle = barStyle;

  //// Constructor

  // Create container
  this.con = document.createElement('DIV');
  this.con.className = this.conStyle;
  // Create bar
  this.bar = document.createElement('DIV');
  this.bar.className = this.barStyle;
  // Insert in object tree
  this.con.appendChild(this.bar);
  document.body.appendChild(this.con);

} // end xBar
// xCapitalize, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

// Capitalize the first letter of every word in str.

function xCapitalize(str)
{
  var i, c, wd, s='', cap = true;
  
  for (i = 0; i < str.length; ++i) {
    c = str.charAt(i);
    wd = isWordDelim(c);
    if (wd) {
      cap = true;
    }  
    if (cap && !wd) {
      c = c.toUpperCase();
      cap = false;
    }
    s += c;
  }
  return s;

  function isWordDelim(c)
  {
    // add other word delimiters as needed
    // (for example '-' and other punctuation)
    return c == ' ' || c == '\n' || c == '\t';
  }
}
// xCardinalPosition, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xCardinalPosition(e, cp, margin, outside)
{
  if(!(e=xGetElementById(e))) return;
  if (typeof(cp)!='string'){window.status='xCardinalPosition error: cp=' + cp + ', id=' + e.id; return;}
  var x=xLeft(e), y=xTop(e), w=xWidth(e), h=xHeight(e);
  var pw,ph,p = xParent(e);
  if (p == document || p.nodeName.toLowerCase() == 'html') {pw = xClientWidth(); ph = xClientHeight();}
  else {pw=xWidth(p); ph=xHeight(p);}
  var sx=xScrollLeft(p), sy=xScrollTop(p);
  var right=sx + pw, bottom=sy + ph;
  var cenLeft=sx + Math.floor((pw-w)/2), cenTop=sy + Math.floor((ph-h)/2);
  if (!margin) margin=0;
  else{
    if (outside) margin=-margin;
    sx +=margin; sy +=margin; right -=margin; bottom -=margin;
  }
  switch (cp.toLowerCase()){
    case 'n': x=cenLeft; if (outside) y=sy - h; else y=sy; break;
    case 'ne': if (outside){x=right; y=sy - h;}else{x=right - w; y=sy;}break;
    case 'e': y=cenTop; if (outside) x=right; else x=right - w; break;
    case 'se': if (outside){x=right; y=bottom;}else{x=right - w; y=bottom - h}break;
    case 's': x=cenLeft; if (outside) y=sy - h; else y=bottom - h; break;
    case 'sw': if (outside){x=sx - w; y=bottom;}else{x=sx; y=bottom - h;}break;
    case 'w': y=cenTop; if (outside) x=sx - w; else x=sx; break;
    case 'nw': if (outside){x=sx - w; y=sy - h;}else{x=sx; y=sy;}break;
    case 'cen': x=cenLeft; y=cenTop; break;
    case 'cenh': x=cenLeft; break;
    case 'cenv': y=cenTop; break;
  }
  var o = new Object();
  o.x = x; o.y = y;
  return o;
}
// xClientHeight, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xClientHeight()
{
  var v=0,d=document,w=window;
  if(d.compatMode == 'CSS1Compat' && !w.opera && d.documentElement && d.documentElement.clientHeight)
    {v=d.documentElement.clientHeight;}
  else if(d.body && d.body.clientHeight)
    {v=d.body.clientHeight;}
  else if(xDef(w.innerWidth,w.innerHeight,d.width)) {
    v=w.innerHeight;
    if(d.width>w.innerWidth) v-=16;
  }
  return v;
}
// xClientWidth, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xClientWidth()
{
  var v=0,d=document,w=window;
  if(d.compatMode == 'CSS1Compat' && !w.opera && d.documentElement && d.documentElement.clientWidth)
    {v=d.documentElement.clientWidth;}
  else if(d.body && d.body.clientWidth)
    {v=d.body.clientWidth;}
  else if(xDef(w.innerWidth,w.innerHeight,d.height)) {
    v=w.innerWidth;
    if(d.height>w.innerHeight) v-=16;
  }
  return v;
}
// xClip, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xClip(e,t,r,b,l)
{
  if(!(e=xGetElementById(e))) return;
  if(e.style) {
    if (xNum(l)) e.style.clip='rect('+t+'px '+r+'px '+b+'px '+l+'px)';
    else e.style.clip='rect(0 '+parseInt(e.style.width)+'px '+parseInt(e.style.height)+'px 0)';
  }
}
// Original by moi. Modified by Mike Foster.
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xColEqualizer()
{
  var i, j, h = [];
  // get heights of columns' child elements
  for (i = 1, j = 0; i < arguments.length; i += 2, ++j)
  {
    h[j] = xHeight(arguments[i]);
  }
  h.sort(d);
  // set heights of column elements
  for (i = 0; i < arguments.length; i += 2)
  {
    xHeight(arguments[i], h[0]);
  }
  return h[0];
  // for a descending sort
  function d(a,b)
  {
    return b-a;
  }
}
// xCollapsible, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xCollapsible(outerEle, bShow) // object prototype
{
  // Constructor

  var container = xGetElementById(outerEle);
  if (!container) {return null;}
  var isUL = container.nodeName.toUpperCase() == 'UL';
  var i, trg, aTgt = xGetElementsByTagName(isUL ? 'UL':'DIV', container);
  for (i = 0; i < aTgt.length; ++i) {
    trg = xPrevSib(aTgt[i]);
    if (trg && (isUL || trg.nodeName.charAt(0).toUpperCase() == 'H')) {
      aTgt[i].xTrgPtr = trg;
      aTgt[i].style.display = bShow ? 'block' : 'none';
      trg.style.cursor = 'pointer';
      trg.xTgtPtr = aTgt[i];
      trg.onclick = trg_onClick;
    }  
  }
  
  // Private

  function trg_onClick()
  {
    var tgt = this.xTgtPtr.style;
    tgt.display = (tgt.display == 'none') ? "block" : "none";
  }

  // Public

  this.displayAll = function(bShow)
  {
    for (var i = 0; i < aTgt.length; ++i) {
      if (aTgt[i].xTrgPtr) {
        aTgt[i].style.display = bShow ? "block" : "none";
      }
    }
  };

  // The unload listener is for IE's circular reference memory leak bug.
  this.onUnload = function()
  {
    if (!container || !aTgt) {return;}
    for (i = 0; i < aTgt.length; ++i) {
      trg = aTgt[i].xTrgPtr;
      if (trg) {
        if (trg.xTgtPtr) {
          trg.xTgtPtr.TrgPtr = null;
          trg.xTgtPtr = null;
        }
        trg.onclick = null;
      }
    }
  };
}


// xColor, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xColor(e,s)
{
  if(!(e=xGetElementById(e))) return '';
  var c='';
  if(e.style && xDef(e.style.color)) {
    if(xStr(s)) e.style.color=s;
    c=e.style.color;
  }
  return c;
}
// xCreateElement, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xCreateElement(sTag)
{
  if (document.createElement) return document.createElement(sTag);
  else return null;
}
// xDef, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xDef()
{
  for(var i=0; i<arguments.length; ++i){if(typeof(arguments[i])=='undefined') return false;}
  return true;
}
// xDeg, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xDeg(rad)
{
  return rad * (180 / Math.PI);
}
// xDeleteCookie, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xDeleteCookie(name, path)
{
  if (xGetCookie(name)) {
    document.cookie = name + "=" +
                    "; path=" + ((!path) ? "/" : path) +
                    "; expires=" + new Date(0).toGMTString();
  }
}
// xDialog, Adapted from xPopup by Aaron Throckmorton
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xDialog(sPos1, sPos2, sPos3, sStyle, sId, sUrl, bHidden)
{
  if (document.getElementById && document.createElement &&
    document.body && document.body.appendChild) {
    // create popup element
    //var e = document.createElement('DIV');
    var e = document.createElement('IFRAME');
    this.ele = e;
    e.id = sId;
    e.name = sId;
    e.style.position = 'absolute';
    e.style.zIndex = '1000';
    e.className = sStyle;
    //e.innerHTML = sHtml;
    e.src = sUrl;
    document.body.appendChild(e);
    xShow(e);
    this.open = false;
    this.margin = 10;
    this.pos1 = sPos1;
    this.pos2 = sPos2;
    this.pos3 = sPos3;
    this.slideTime = 400; // slide time in ms
    if (bHidden) xHide(sId);
    else this.show();
  }
} // end xDialog

// methods
xDialog.prototype.show = function() {
  if (!this.open) {
    var e = this.ele;
    var pos = xCardinalPosition(e, this.pos1, this.margin, true);
    xMoveTo(e, pos.x, pos.y);
    xShow(e);
    pos = xCardinalPosition(e, this.pos2, this.margin, false);
    xSlideTo(e, pos.x, pos.y, this.slideTime);
    this.open = true;
  }
};

xDialog.prototype.hide = function() {
  if (this.open) {
    var e = this.ele;
    var pos = xCardinalPosition(e, this.pos3, this.margin, true);
    xSlideTo(e, pos.x, pos.y, this.slideTime);
    setTimeout("xHide('" + e.id + "')", this.slideTime);
    //setTimeout("xMoveTo('" + e.id + "', 1 , 1)", this.slideTime);
    this.open = false;
  }
};

/*
xDialog.prototype.destroy = function(sobj) {
  this.hide();
  //setTimeout("document.body.removeChild(getElementById('" + sobj + "'))", this.slideTime);
  setTimeout(sobj + " = ''", this.slideTime);
  //document.body.removeChild(this.ele);
  //delete this ;
};*/

xDialog.prototype.setUrl = function(sUrl) {
  this.ele.src = sUrl;
};

xDialog.prototype.resize = function(w, h) {
  xResizeTo(this.ele, w, h);
  if (this.open) {
    var pos = xCardinalPosition(this.ele, this.pos2, this.margin, true);
    xSlideTo(this.ele, pos.x, pos.y, this.slideTime);
  }
};
// xDisableDrag, Copyright 2005-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xDisableDrag(id, last)
{
  if (!window._xDrgMgr) return;
  var ele = xGetElementById(id);
  ele.xDraggable = false;
  ele.xODS = null;
  ele.xOD = null;
  ele.xODE = null;
  xRemoveEventListener(ele, 'mousedown', _xOMD, false);
  if (_xDrgMgr.mm && last) {
    _xDrgMgr.mm = false;
    xRemoveEventListener(document, 'mousemove', _xOMM, false);
  }
}
// xDisableDrop, Copyright 2006-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xDisableDrop(id)
{
  if (!window._xDrgMgr) return;
  var e = xGetElementById(id);
  if (e && e.xODp) {
    e.xODp = null;
    for (i = 0; i < _xDrgMgr.drops.length; ++i) {
      if (e == _xDrgMgr.drops[i]) {
        _xDrgMgr.drops.splice(i, 1);
      }
    }
  }
}
// xDisplay, Copyright 2003-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

// This was alternative 1:

function xDisplay(e,s)
{
  if ((e=xGetElementById(e)) && e.style && xDef(e.style.display)) {
    if (xStr(s)) {
      try { e.style.display = s; }
      catch (ex) { e.style.display = ''; } // Will this make IE use a default value
    }                                      // appropriate for the element?
    return e.style.display;
  }
  return null;
}
// xDocSize, Copyright 2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xDocSize()
{
  var b=document.body, e=document.documentElement;
  var esw=0, eow=0, bsw=0, bow=0, esh=0, eoh=0, bsh=0, boh=0;
  if (e) {
    esw = e.scrollWidth;
    eow = e.offsetWidth;
    esh = e.scrollHeight;
    eoh = e.offsetHeight;
  }
  if (b) {
    bsw = b.scrollWidth;
    bow = b.offsetWidth;
    bsh = b.scrollHeight;
    boh = b.offsetHeight;
  }
//  alert('compatMode: ' + document.compatMode + '\n\ndocumentElement.scrollHeight: ' + esh + '\ndocumentElement.offsetHeight: ' + eoh + '\nbody.scrollHeight: ' + bsh + '\nbody.offsetHeight: ' + boh + '\n\ndocumentElement.scrollWidth: ' + esw + '\ndocumentElement.offsetWidth: ' + eow + '\nbody.scrollWidth: ' + bsw + '\nbody.offsetWidth: ' + bow);
  return {w:Math.max(esw,eow,bsw,bow),h:Math.max(esh,eoh,bsh,boh)};
}
// xEach, Copyright 2006-2007 Daniel Frechette
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

/**
 * Access each element of a collection sequentially (by its numeric index)
 * and do something with it.
 * @param c - Array/Obj - A collection of elements
 * @param f - Func      - Function to execute for each element.
 *                        Arguments: item, index, number of items
 * @param s - Int       - Start index. A number between 0 and collection size - 1. (optional)
 * @return Nothing
 */
function xEach(c, f, s) {
  var l = c.length;
  for (var i=(s || 0); i < l; i++) {
    f(c[i], i, l);
  }
};
// xEachUntilReturn, Copyright 2006-2007 Daniel Frechette
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

/**
 * Access each element of a collection sequentially (by its numeric index)
 * and do something with it. Stop when the called function returns a value.
 * @param c - Array/Obj - A collection of elements
 * @param f - Func      - Function to execute for each element
 *                        Arguments: item, index, number of items
 * @param s - Int       - Start index. A number between 0 and collection size - 1. (optional)
 * @return Any
 */

function xEachUntilReturn(c, f, s) {
  var r, l = c.length;
  for (var i=(s || 0); i < l; i++) {
    r = f(c[i], i, l);
    if (r !== undefined)
      break;
  }
  return r;
};
// xEditable, Copyright 2005-2007 Jerod Venema
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xEditable(container,trigger){

var editElement = null;
var container = xGetElementById(container);
var trigger = xGetElementById(trigger);
var newID = container.id + "_edit";
xAddEventListener(container, 'click', BeginEdit);

function BeginEdit(){
  if(!editElement){
    // create the input box
    editElement = xCreateElement('input');
    editElement.setAttribute('id', newID);
    editElement.setAttribute('name', newID);
    // prep the inputbox with the current value
    editElement.setAttribute('value', container.innerHTML);
    // kills small gecko bug
    editElement.setAttribute('autocomplete','OFF');
    // setup events that occur when editing is done
    xAddEventListener(editElement, 'blur', EndEditClick);
    xAddEventListener(editElement, 'keypress', EndEditKey);
    // make room for the inputbox, then add it
    container.innerHTML = '';
    container.appendChild(editElement);
    editElement.select();
    editElement.focus();
  }else{
    editElement.select();
    editElement.focus();
  }
}
function EndEditClick(){
  // save the entered value, and kill the input field
  container.innerHTML = editElement.value;
  editElement = null;
}
function EndEditKey(evt){
  // save the entered value, and kill the input field, but ONLY on an enter
  var e = new xEvent(evt);
  if(e.keyCode == 13){
    container.innerHTML = editElement.value;
    editElement = null;
  }
}
}
// xEllipse, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xEllipse(e, xRadius, yRadius, radiusInc, totalTime, startAngle, stopAngle)
{
  if (!(e=xGetElementById(e))) return;
  if (!e.timeout) e.timeout = 25;
  e.xA = xRadius;
  e.yA = yRadius;
  e.radiusInc = radiusInc;
  e.slideTime = totalTime;
  startAngle *= (Math.PI / 180);
  stopAngle *= (Math.PI / 180);
  var startTime = (startAngle * e.slideTime) / (stopAngle - startAngle);
  e.stopTime = e.slideTime + startTime;
  e.B = (stopAngle - startAngle) / e.slideTime;
  e.xD = xLeft(e) - Math.round(e.xA * Math.cos(e.B * startTime)); // center point
  e.yD = xTop(e) - Math.round(e.yA * Math.sin(e.B * startTime)); 
  e.xTarget = Math.round(e.xA * Math.cos(e.B * e.stopTime) + e.xD); // end point
  e.yTarget = Math.round(e.yA * Math.sin(e.B * e.stopTime) + e.yD); 
  var d = new Date();
  e.C = d.getTime() - startTime;
  if (!e.moving) {e.stop=false; _xEllipse(e);}
}
function _xEllipse(e)
{
  if (!(e=xGetElementById(e))) return;
  var now, t, newY, newX;
  now = new Date();
  t = now.getTime() - e.C;
  if (e.stop) { e.moving = false; }
  else if (t < e.stopTime) {
    setTimeout("_xEllipse('"+e.id+"')", e.timeout);
    if (e.radiusInc) {
      e.xA += e.radiusInc;
      e.yA += e.radiusInc;
    }
    newX = Math.round(e.xA * Math.cos(e.B * t) + e.xD);
    newY = Math.round(e.yA * Math.sin(e.B * t) + e.yD);
    xMoveTo(e, newX, newY);
    e.moving = true;
  }  
  else {
    if (e.radiusInc) {
      e.xTarget = Math.round(e.xA * Math.cos(e.B * e.slideTime) + e.xD);
      e.yTarget = Math.round(e.yA * Math.sin(e.B * e.slideTime) + e.yD); 
    }
    xMoveTo(e, e.xTarget, e.yTarget);
    e.moving = false;
    if (e.onslideend) e.onslideend();
  }  
}
// xEnableDrag, Copyright 2002-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

var _xDrgMgr = {ele:null, mm:false};
function xEnableDrag(id,fS,fD,fE,x1,y1,x2,y2)
{
  var el = xGetElementById(id);
  if (el) {
    el.xDraggable = true;
    el.xODS = fS;
    el.xOD = fD;
    el.xODE = fE;
    el.xREC = null;
    if (xDef(x1,y1,x2,y2)) {el.xREC = {x1:x1,y1:y1,x2:x2,y2:y2};}
    xAddEventListener(el, 'mousedown', _xOMD, false);
    if (!_xDrgMgr.mm) {
      _xDrgMgr.mm = true;
      xAddEventListener(document, 'mousemove', _xOMM, false);
    }
  }
}
function _xOMD(e) // drag start
{
  var ev = new xEvent(e);
  if (ev.button != 0) return;
  var t = ev.target;
  while(t && !t.xDraggable) { t = xParent(t); }
  if (t) {
    xPreventDefault(e);
    t.xDPX = ev.pageX;
    t.xDPY = ev.pageY;
    _xDrgMgr.ele = t;
    xAddEventListener(document, 'mouseup', _xOMU, false);
    if (t.xODS) { t.xODS(t, ev.pageX, ev.pageY); }
  }
}
function _xOMM(e) // drag
{
  var ev = new xEvent(e);
  if (_xDrgMgr.ele) {
    xPreventDefault(e);
    var b = true, el = _xDrgMgr.ele;
    var dx = ev.pageX - el.xDPX;
    var dy = ev.pageY - el.xDPY;
    el.xDPX = ev.pageX;
    el.xDPY = ev.pageY;
    if (el.xREC) { 
      var r = el.xREC, x = xPageX(el) + dx, y = xPageY(el) + dy;
      var b = (x >= r.x1 && x+xWidth(el) <= r.x2 && y >= r.y1 && y+xHeight(el) <= r.y2);
    }
    if (el.xOD) { el.xOD(el, dx, dy, b); }
    else if (b) { xMoveTo(el, xLeft(el) + dx, xTop(el) + dy); }
  }
}
function _xOMU(e) // drag end
{
  if (_xDrgMgr.ele) {
    xPreventDefault(e);
    xRemoveEventListener(document, 'mouseup', _xOMU, false);
    if (_xDrgMgr.ele.xODE) {
      var ev = new xEvent(e);
      _xDrgMgr.ele.xODE(_xDrgMgr.ele, ev.pageX, ev.pageY);
    }
    _xDrgMgr.ele = null;
  }
}
// xEnableDrop, Copyright 2006-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xEnableDrop(id,fD)
{
  var e = xGetElementById(id);
  if (e) {
    e.xODp = fD;
    if (!_xDrgMgr.drops) {
      _xDrgMgr.drops = new Array();
    }
    _xDrgMgr.drops[_xDrgMgr.drops.length] = e;
    if (!_xDrgMgr.omu) {
      _xDrgMgr.omu = _xOMU;
      _xOMU = _xOMU2;
    }
  }
}
function _xOMU2(e) // this over-rides _xOMU in xenabledrag.js
{
  var i, z, hz = 0, he = null;
  e = new xEvent(e);
  for (i = 0; i < _xDrgMgr.drops.length; ++i) {
    if (xHasPoint(_xDrgMgr.drops[i], e.pageX, e.pageY)) {
      z = xZIndex(_xDrgMgr.drops[i]) || 0;
      if (z >= hz) {
        hz = z;
        he = _xDrgMgr.drops[i];
      } 
    }
  }
  var ele = _xDrgMgr.ele;
  _xDrgMgr.omu(e); // dragEnd event
  if (he && he.xODp) {
    he.xODp(ele, e.pageX, e.pageY); // drop event
  }
}
// xEvalTextarea, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xEvalTextarea()
{
  var f = document.createElement('FORM');
  f.onsubmit = 'return false';
  var t = document.createElement('TEXTAREA');
  t.id='xDebugTA';
  t.name='xDebugTA';
  t.rows='20';
  t.cols='60';
  var b = document.createElement('INPUT');
  b.type = 'button';
  b.value = 'Evaluate';
  b.onclick = function() {eval(this.form.xDebugTA.value);};
  f.appendChild(t);
  f.appendChild(b);
  document.body.appendChild(f);
}
// xEvent, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xEvent(evt) // object prototype
{
  var e = evt || window.event;
  if(!e) return;
  if(e.type) this.type = e.type;
  if(e.target) this.target = e.target;
  else if(e.srcElement) this.target = e.srcElement;
  // Section B
  if (e.relatedTarget) this.relatedTarget = e.relatedTarget;
  else if (e.type == 'mouseover' && e.fromElement) this.relatedTarget = e.fromElement;
  else if (e.type == 'mouseout') this.relatedTarget = e.toElement;
  // End Section B
  if(xDef(e.pageX,e.pageY)) { this.pageX = e.pageX; this.pageY = e.pageY; }
  else if(xDef(e.clientX,e.clientY)) { this.pageX = e.clientX + xScrollLeft(); this.pageY = e.clientY + xScrollTop(); }
  // Section A
  if (xDef(e.offsetX,e.offsetY)) {
    this.offsetX = e.offsetX;
    this.offsetY = e.offsetY;
  }
  else if (xDef(e.layerX,e.layerY)) {
    this.offsetX = e.layerX;
    this.offsetY = e.layerY;
  }
  else {
    this.offsetX = this.pageX - xPageX(this.target);
    this.offsetY = this.pageY - xPageY(this.target);
  }
  // End Section A
  this.keyCode = e.keyCode || e.which || 0;
  this.shiftKey = e.shiftKey;
  this.ctrlKey = e.ctrlKey;
  this.altKey = e.altKey;
  // rev6
  this.button = 3; // 0=left, 1=middle, 2=right, 3=none-mouse event
  if (e.type.indexOf('click') != -1) {this.button = 0;}
  else if (e.type.indexOf('mouse') != -1) {
    /*@cc_on
    @if (@_jscript_version) // any IE
      if (e.button == 1) this.button = 0;
      else if (e.button == 4) this.button = 1;
      else if (e.button == 2) this.button = 2;
    @else @*/
      this.button = e.button;
    /*@end @*/
  }
}
// xFenster, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xFenster(eleId, iniX, iniY, barId, resBtnId, maxBtnId) // object prototype
{
  // Private Properties
  var me = this;
  var ele = xGetElementById(eleId);
  var rBtn = xGetElementById(resBtnId);
  var mBtn = xGetElementById(maxBtnId);
  var x, y, w, h, maximized = false;
  // Public Methods
  this.onunload = function()
  {
    if (!window.opera) { // clear cir refs
      xDisableDrag(barId);
      xDisableDrag(rBtn);
      mBtn.onclick = ele.onmousedown = null;
      me = ele = rBtn = mBtn = null;
    }
  };
  this.paint = function()
  {
    xMoveTo(rBtn, xWidth(ele) - xWidth(rBtn), xHeight(ele) - xHeight(rBtn));
    xMoveTo(mBtn, xWidth(ele) - xWidth(mBtn), 0);
  };
  // Private Event Listeners
  function barOnDrag(e, mdx, mdy)
  {
    // Thanks to Jen for this feature:
    var x = xLeft(ele) + mdx;
    var y = xTop(ele) + mdy;
    if (x < 0) x = 0;
    if (y < 0) y = 0;
    xMoveTo(ele, x, y);
  }
  function resOnDrag(e, mdx, mdy)
  {
    xResizeTo(ele, xWidth(ele) + mdx, xHeight(ele) + mdy);
    me.paint();
  }
  function fenOnMousedown()
  {
    xZIndex(ele, xFenster.z++);
  }
  function maxOnClick()
  {
    if (maximized) {
      maximized = false;
      xResizeTo(ele, w, h);
      xMoveTo(ele, x, y);
    }
    else {
      w = xWidth(ele);
      h = xHeight(ele);
      x = xLeft(ele);
      y = xTop(ele);
      xMoveTo(ele, xScrollLeft(), xScrollTop());
      maximized = true;
      xResizeTo(ele, xClientWidth(), xClientHeight());
    }
    me.paint();
  }
  // Constructor Code
  xFenster.z++;
  xMoveTo(ele, iniX, iniY);
  this.paint();
  xEnableDrag(barId, null, barOnDrag, null);
  xEnableDrag(rBtn, null, resOnDrag, null);
  mBtn.onclick = maxOnClick;
  ele.onmousedown = fenOnMousedown;
  xShow(ele);
} // end xFenster object prototype

xFenster.z = 0; // xFenster static property
// xFindAfterByClassName, Copyright 2005-2007 Olivier Spinelli
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xFindAfterByClassName( ele, clsName )
{
  var re = new RegExp('\\b'+clsName+'\\b', 'i');
  return xWalkToLast( ele, function(n){if(n.className.search(re) != -1)return n;} );
}
// xFindBeforeByClassName, Copyright 2005-2007 Olivier Spinelli
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xFindBeforeByClassName( ele, clsName )
{
  var re = new RegExp('\\b'+clsName+'\\b', 'i');
  return xWalkToFirst( ele, function(n){if(n.className.search(re) != -1)return n;} );
}
// xFirstChild, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xFirstChild(e,t)
{
  e = xGetElementById(e);
  var c = e ? e.firstChild : null;
  while (c) {
    if (c.nodeType == 1 && (!t || c.nodeName.toLowerCase() == t.toLowerCase())){break;}
    c = c.nextSibling;
  }
  return c;
}
// xGetComputedStyle, Copyright 2002-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xGetComputedStyle(oEle, sProp, bInt)
{
  var s, p = 'undefined';
  var dv = document.defaultView;
  if(dv && dv.getComputedStyle){
    s = dv.getComputedStyle(oEle,'');
    if (s) p = s.getPropertyValue(sProp);
  }
  else if(oEle.currentStyle) {
    // convert css property name to object property name for IE
    var i, c, a = sProp.split('-');
    sProp = a[0];
    for (i=1; i<a.length; ++i) {
      c = a[i].charAt(0);
      sProp += a[i].replace(c, c.toUpperCase());
    }
    p = oEle.currentStyle[sProp];
  }
  else return null;
  return bInt ? (parseInt(p) || 0) : p;
}

// xGetCookie, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xGetCookie(name)
{
  var value=null, search=name+"=";
  if (document.cookie.length > 0) {
    var offset = document.cookie.indexOf(search);
    if (offset != -1) {
      offset += search.length;
      var end = document.cookie.indexOf(";", offset);
      if (end == -1) end = document.cookie.length;
      value = unescape(document.cookie.substring(offset, end));
    }
  }
  return value;
}
// xGetCSSRules, Copyright 2006-2007 Ivan Pepelnjak (www.zaplana.net)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

//
// xGetCSSRules - extracts CSS rules from the style sheet object (IE vs. DOM CSS level 2)
//
function xGetCSSRules(ss) { return ss.rules ? ss.rules : ss.cssRules; }
// xGetEleAtPoint, Copyright 2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xGetEleAtPoint(x, y)
{
  var he = null, z, hz = 0;
  var i, list = xGetElementsByTagName('*');
  for (i = 0; i < list.length; ++i) {
    if (xHasPoint(list[i], x, y)) {
      z = xZIndex(list[i]);
      z = z || 0;
      if (z >= hz) {
        hz = z;
        he = list[i];
      } 
    }
  }
  return he;
}
// xGetElementById, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xGetElementById(e)
{
  if(typeof(e)=='string') {
    if(document.getElementById) e=document.getElementById(e);
    else if(document.all) e=document.all[e];
    else e=null;
  }
  return e;
}
// xGetElementsByAttribute, Copyright 2002-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xGetElementsByAttribute(sTag, sAtt, sRE, fn)
{
  var a, list, found = new Array(), re = new RegExp(sRE, 'i');
  list = xGetElementsByTagName(sTag);
  for (var i = 0; i < list.length; ++i) {
    a = list[i].getAttribute(sAtt);
    if (!a) {a = list[i][sAtt];}
    if (typeof(a)=='string' && a.search(re) != -1) {
      found[found.length] = list[i];
      if (fn) fn(list[i]);
    }
  }
  return found;
}
// xGetElementsByClassName, Copyright 2002-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xGetElementsByClassName(c,p,t,f)
{
  var r = new Array();
  var re = new RegExp("(^|\\s)"+c+"(\\s|$)");
//  var e = p.getElementsByTagName(t);
  var e = xGetElementsByTagName(t,p); // See xml comments.
  for (var i = 0; i < e.length; ++i) {
    if (re.test(e[i].className)) {
      r[r.length] = e[i];
      if (f) f(e[i]);
    }
  }
  return r;
}
// xGetElementsByTagName, Copyright 2002-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xGetElementsByTagName(t,p)
{
  var list = null;
  t = t || '*';
  p = p || document;
  if (typeof p.getElementsByTagName != 'undefined') { // DOM1
    list = p.getElementsByTagName(t);
    if (t=='*' && (!list || !list.length)) list = p.all; // IE5 '*' bug
  }
  else { // IE4 object model
    if (t=='*') list = p.all;
    else if (p.all && p.all.tags) list = p.all.tags(t);
  }
  return list || new Array();
}
// xGetElePropsArray, Copyright 2002-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xGetElePropsArray(ele, eleName)
{
  var u = 'undefined';
  var i = 0, a = new Array();
  
  nv('Element', eleName);
  nv('id', (xDef(ele.id) ? ele.id : u));
  nv('tagName', (xDef(ele.tagName) ? ele.tagName : u));

  nv('xWidth()', xWidth(ele));
  nv('style.width', (xDef(ele.style) && xDef(ele.style.width) ? ele.style.width : u));
  nv('offsetWidth', (xDef(ele.offsetWidth) ? ele.offsetWidth : u));
  nv('scrollWidth', (xDef(ele.offsetWidth) ? ele.offsetWidth : u));
  nv('clientWidth', (xDef(ele.clientWidth) ? ele.clientWidth : u));

  nv('xHeight()', xHeight(ele));
  nv('style.height', (xDef(ele.style) && xDef(ele.style.height) ? ele.style.height : u));
  nv('offsetHeight', (xDef(ele.offsetHeight) ? ele.offsetHeight : u));
  nv('scrollHeight', (xDef(ele.offsetHeight) ? ele.offsetHeight : u));
  nv('clientHeight', (xDef(ele.clientHeight) ? ele.clientHeight : u));

  nv('xLeft()', xLeft(ele));
  nv('style.left', (xDef(ele.style) && xDef(ele.style.left) ? ele.style.left : u));
  nv('offsetLeft', (xDef(ele.offsetLeft) ? ele.offsetLeft : u));
  nv('style.pixelLeft', (xDef(ele.style) && xDef(ele.style.pixelLeft) ? ele.style.pixelLeft : u));

  nv('xTop()', xTop(ele));
  nv('style.top', (xDef(ele.style) && xDef(ele.style.top) ? ele.style.top : u));
  nv('offsetTop', (xDef(ele.offsetTop) ? ele.offsetTop : u));
  nv('style.pixelTop', (xDef(ele.style) && xDef(ele.style.pixelTop) ? ele.style.pixelTop : u));

  nv('', '');
  nv('xGetComputedStyle()', '');

  nv('top');
  nv('right');
  nv('bottom');
  nv('left');

  nv('width');
  nv('height');

  nv('color');
  nv('background-color');
  nv('font-family');
  nv('font-size');
  nv('text-align');
  nv('line-height');
  nv('content');
  
  nv('float');
  nv('clear');

  nv('margin');
  nv('padding');
  nv('padding-top');
  nv('padding-right');
  nv('padding-bottom');
  nv('padding-left');

  nv('border-top-width');
  nv('border-right-width');
  nv('border-bottom-width');
  nv('border-left-width');

  nv('position');
  nv('overflow');
  nv('visibility');
  nv('display');
  nv('z-index');
  nv('clip');
  nv('cursor');

  return a;

  function nv(name, value)
  {
    a[i] = new Object();
    a[i].name = name;
    a[i].value = typeof(value)=='undefined' ? xGetComputedStyle(ele, name) : value;
    ++i;
  }
}
// xGetElePropsString, Copyright 2002-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xGetElePropsString(ele, eleName, newLine)
{
  var s = '', a = xGetElePropsArray(ele, eleName);
  for (var i = 0; i < a.length; ++i) {
    s += a[i].name + ' = ' + a[i].value + (newLine || '\n');
  }
  return s;
}
// xGetStyleSheetFromLink, Copyright 2006-2007 Ivan Pepelnjak (www.zaplana.net)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

//
// xGetStyleSheetFromLink - extracts style sheet object from the HTML LINK object (IE vs. DOM CSS level 2)
//
function xGetStyleSheetFromLink(cl) { return cl.styleSheet ? cl.styleSheet : cl.sheet; }

// xGetURLArguments, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xGetURLArguments()
{
  var idx = location.href.indexOf('?');
  var params = new Array();
  if (idx != -1) {
    var pairs = location.href.substring(idx+1, location.href.length).split('&');
    for (var i=0; i<pairs.length; i++) {
      nameVal = pairs[i].split('=');
      params[i] = nameVal[1];
      params[nameVal[0]] = nameVal[1];
    }
  }
  return params;
}
// xHasClass, Copyright 2005-2007 Daniel Frechette
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

/**
 * @param e - Str/Obj - Element id or object
 * @param c - Str     - Class name
 * @return Bool - true if found, false otherwise
 */
function xHasClass(e, c) {
  e = xGetElementById(e);
  if (!e || !e.className)
    return false;
  return (e.className == c) || e.className.match(new RegExp('\\b'+c+'\\b'));
};
// xHasPoint, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xHasPoint(e,x,y,t,r,b,l)
{
  if (!xNum(t)){t=r=b=l=0;}
  else if (!xNum(r)){r=b=l=t;}
  else if (!xNum(b)){l=r; b=t;}
  var eX = xPageX(e), eY = xPageY(e);
  return (x >= eX + l && x <= eX + xWidth(e) - r &&
          y >= eY + t && y <= eY + xHeight(e) - b );
}
// xTraverseDocumentStyleSheets, Copyright 2006-2007 Ivan Pepelnjak (www.zaplana.net)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

//
// xHasStyleSelector(styleSelectorString)
//   checks whether any of the stylesheets attached to the document contain the definition of the specified
//   style selector (simple string matching at the moment)
//
// returns:
//   undefined  - style sheet scripting not supported by the browser
//   true/false - found/not found
//
function xHasStyleSelector(ss) {
  if (! xHasStyleSheets()) return undefined ;

  function testSelector(cr) {
    return cr.selectorText.indexOf(ss) >= 0;
  }
  return xTraverseDocumentStyleSheets(testSelector);
}
// xHasStyleSheets, Copyright 2006-2007 Ivan Pepelnjak (www.zaplana.net)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

//
// xHasStyleSheets - checks browser support for stylesheet related objects (IE or DOM compliant)
//
function xHasStyleSheets() {
  return document.styleSheets ? true : false ;
}
// xHeight, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xHeight(e,h)
{
  if(!(e=xGetElementById(e))) return 0;
  if (xNum(h)) {
    if (h<0) h = 0;
    else h=Math.round(h);
  }
  else h=-1;
  var css=xDef(e.style);
  if (e == document || e.tagName.toLowerCase() == 'html' || e.tagName.toLowerCase() == 'body') {
    h = xClientHeight();
  }
  else if(css && xDef(e.offsetHeight) && xStr(e.style.height)) {
    if(h>=0) {
      var pt=0,pb=0,bt=0,bb=0;
      if (document.compatMode=='CSS1Compat') {
        var gcs = xGetComputedStyle;
        pt=gcs(e,'padding-top',1);
        if (pt !== null) {
          pb=gcs(e,'padding-bottom',1);
          bt=gcs(e,'border-top-width',1);
          bb=gcs(e,'border-bottom-width',1);
        }
        // Should we try this as a last resort?
        // At this point getComputedStyle and currentStyle do not exist.
        else if(xDef(e.offsetHeight,e.style.height)){
          e.style.height=h+'px';
          pt=e.offsetHeight-h;
        }
      }
      h-=(pt+pb+bt+bb);
      if(isNaN(h)||h<0) return;
      else e.style.height=h+'px';
    }
    h=e.offsetHeight;
  }
  else if(css && xDef(e.style.pixelHeight)) {
    if(h>=0) e.style.pixelHeight=h;
    h=e.style.pixelHeight;
  }
  return h;
}
// xHex, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xHex(n, digits, prefix)
{
  var p = '', n = Math.ceil(n);
  if (prefix) p = prefix;
  n = n.toString(16);
  for (var i=0; i < digits - n.length; ++i) {
    p += '0';
  }
  return p + n;
}
// xHide, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xHide(e){return xVisibility(e,0);}
// xHttpRequest2, Copyright 2006-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

/* I suggest you use xHttpRequest instead of this implementation.
   This one has not been updated since I did more testing and
   updating on the other. This one is interesting for its use of
   the XML island for IE - but that is all.
*/

function xHttpRequest2() // object prototype
{
  // Public Properties
  this.xmlDoc = null;
  this.busy = false;
  this.err = {};
  // Private Properties
  var _i = this; // instance object
  var _r = null; // XMLHttpRequest object
  var _t = null; // timer
  var _f = null; // callback function
  /*@cc_on var _x = null; @*/ // xml element for IE
  // Private Event Listeners
  function _oc() // onReadyStateChange
  {
    if (_r.readyState == 4) {
      if (_t) { clearTimeout(_t); }
      _i.busy = false;
      if (_f) {
        if (_i.xmlDoc == 1 && _r.status == 200) {
          /*@cc_on
          @if (@_jscript_version < 5.9) // IE (this is a guess - need a better check here)
          if (!_x) {
            _x = document.createElement('xml');
            document.body.appendChild(_x);
          }
          _x.XMLDocument.loadXML(_r.responseText);
          _i.xmlDoc = _x.XMLDocument;
          @else @*/
          _i.xmlDoc = _r.responseXML;
          /*@end @*/
        }
        _f(_i, _r);
      } // end if (_f)
    }
  }
  function _ot() // onTimeout
  {
    _i.err.name = 'Timeout';
    _r.abort();
    _i.busy = false;
    if (_f) _f(_i, null);
  }
  // Public Method
  this.send = function(m, u, d, t, r, x, f)
  {
    if (!_r) { return false; }
    if (_i.busy) {
      _i.err.name = 'Busy';
      return false;
    }
    m = m.toUpperCase();
    if (m != 'POST') {
      if (d) {
        d = '?' + d;
        if (r) { d += '&' + r + '=' + Math.round(10000*Math.random()); }
      }
      else { d = ''; }
    }
    _f = f;
    _i.xmlDoc = null;
    _i.err.name = _i.err.message = '';
    _i.busy = true;
    if (t) { _t = setTimeout(_ot, t); }
    try {
      if (m == 'GET') {
        _r.open(m, u + d, true);
        d = null;
        _r.setRequestHeader('Cache-Control', 'no-cache'); // this doesn't prevent caching in IE
        if (x) {
          if (_r.overrideMimeType) { _r.overrideMimeType('text/xml'); }
          _r.setRequestHeader('Content-Type', 'text/xml');
          _i.xmlDoc = 1; // indicate to _oc that xml is expected
        }
      }
      else if (m == 'POST') {
        _r.open(m, u, true);
        _r.setRequestHeader('Method', 'POST ' + u + ' HTTP/1.1');
        _r.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
      }
      else {
        _r.open(m, u + d, true);
        d = null;
      }
      _r.onreadystatechange = _oc;
      _r.send(d);
    }
    catch(e) {
      if (_t) { clearTimeout(_t); }
      _f = null;
      _i.busy = false;
      _i.err.name = e.name;
      _i.err.message = e.message;
      return false;
    }
    return true;
  };
  // Constructor Code
  try { _r = new XMLHttpRequest(); }
  catch (e) { try { _r = new ActiveXObject('Msxml2.XMLHTTP'); }
  catch (e) { try { _r = new ActiveXObject('Microsoft.XMLHTTP'); }
  catch (e) { _r = null; }}}
  if (!_r) { _i.err.name = 'Unsupported'; }
}
// xHttpRequest, Copyright 2006-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xHttpRequest() // object prototype
{
  // Private Properties
  var _i = this; // instance object
  var _r = null; // XMLHttpRequest object
  var _t = null; // timer
  var _f = null; // callback function
  var _x = false; // XML response pending
  var _o = null; // user data object passed to _f
  // Public Properties
  _i.OK = 0;
  _i.NOXMLOBJ = 1;
  _i.REQERR = 2;
  _i.TIMEOUT = 4;
  _i.RSPERR = 8;
  _i.NOXMLCT = 16;
  _i.status = _i.OK;
  _i.busy = false;
  // Private Event Listeners
  function _oc() // onReadyStateChange
  {
    if (_r.readyState == 4) {
      if (_t) { clearTimeout(_t); }
      if (_r.status != 200) _i.status = _i.RSPERR;
      if (_x) {
        var ct = _r.getResponseHeader('Content-Type');
        if (ct && ct.indexOf('xml') == -1) { _i.status |= _i.NOXMLCT; }
      }
      if (_f) _f(_r, _i.status, _o);
      _i.busy = false;
    }
  }
  function _ot() // onTimeout
  {
    _r.abort();
    _i.status |= _i.TIMEOUT;
    if (_f) _f(_r, _i.status, _o);
    _i.busy = false;
  }
  // Public Method
  this.send = function(m, u, d, t, r, x, o, f)
  {
    if (!_r || _i.busy) { return false; }
    m = m.toUpperCase();
    if (m != 'POST') {
      if (d) {
        d = '?' + d;
        if (r) { d += '&' + r + '=' + Math.round(10000*Math.random()); }
      }
      else { d = ''; }
    }
    _x = x;
    _o = o;
    _f = f;
    _i.busy = true;
    _i.status = _i.OK;
    if (t) { _t = setTimeout(_ot, t); }
    try {
      if (m == 'GET') {
        _r.open(m, u + d, true);
        d = null;
        _r.setRequestHeader('Cache-Control', 'no-cache');
        var ct = 'text/' + (x ? 'xml':'plain');
        if (_r.overrideMimeType) {_r.overrideMimeType(ct);}
        _r.setRequestHeader('Content-Type', ct);
      }
      else if (m == 'POST') {
        _r.open(m, u, true);
        _r.setRequestHeader('Method', 'POST ' + u + ' HTTP/1.1');
        _r.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
      }
      else {
        _r.open(m, u + d, true);
        d = null;
      }
      _r.onreadystatechange = _oc;
      _r.send(d);
    }
    catch(e) {
      if (_t) { clearTimeout(_t); }
      _f = null;
      _i.busy = false;
      _i.status = _i.REQERR;
      _i.error = e;
      return false;
    }
    return true;
  };
  // Constructor Code
  try { _r = new XMLHttpRequest(); }
  catch (e) { try { _r = new ActiveXObject('Msxml2.XMLHTTP'); }
  catch (e) { try { _r = new ActiveXObject('Microsoft.XMLHTTP'); }
  catch (e) { _r = null; }}}
  if (!_r) { _i.status = _i.NOXMLOBJ; }
}
// xImgAsyncWait, Copyright 2003-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xImgAsyncWait(fnStatus, fnInit, fnError, sErrorImg, sAbortImg, imgArray)
{
  var i, imgs = imgArray || document.images;
  
  for (i = 0; i < imgs.length; ++i) {
    imgs[i].onload = imgOnLoad;
    imgs[i].onerror = imgOnError;
    imgs[i].onabort = imgOnAbort;
  }
  
  xIAW.fnStatus = fnStatus;
  xIAW.fnInit = fnInit;
  xIAW.fnError = fnError;
  xIAW.imgArray = imgArray;

  xIAW();

  function imgOnLoad()
  {
    this.wasLoaded = true;
  }
  function imgOnError()
  {
    if (sErrorImg && !this.wasError) {
      this.src = sErrorImg;
    }
    this.wasError = true;
  }
  function imgOnAbort()
  {
    if (sAbortImg && !this.wasAborted) {
      this.src = sAbortImg;
    }
    this.wasAborted = true;
  }
}
// end xImgAsyncWait()

// Don't call xIAW() directly. It is only called from xImgAsyncWait().

function xIAW()
{
  var me = arguments.callee;
  if (!me) {
    return; // I could have used a global object instead of callee
  }
  var i, imgs = me.imgArray ? me.imgArray : document.images;
  var c = 0, e = 0, a = 0, n = imgs.length;
  for (i = 0; i < n; ++i) {
    if (imgs[i].wasError) {
      ++e;
    }
    else if (imgs[i].wasAborted) {
      ++a;
    }
    else if (imgs[i].complete || imgs[i].wasLoaded) {
      ++c;
    }
  }
  if (me.fnStatus) {
    me.fnStatus(n, c, e, a);
  }
  if (c + e + a == n) {
    if ((e || a) && me.fnError) {
      me.fnError(n, c, e, a);
    }
    else if (me.fnInit) {
      me.fnInit();
    }
  }
  else setTimeout('xIAW()', 250);
}
// end xIAW()
// xImgRollSetup, Copyright 2002-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xImgRollSetup(p,s,x)
{
  var ele, id;
  for (var i=3; i<arguments.length; ++i) {
    id = arguments[i];
    if (ele = xGetElementById(id)) {
      ele.xIOU = p + id + x;
      ele.xIOO = new Image();
      ele.xIOO.src = p + id + s + x;
      ele.onmouseout = imgOnMouseout;
      ele.onmouseover = imgOnMouseover;
    }
  }
  function imgOnMouseout(e)
  {
    if (this.xIOU) {
      this.src = this.xIOU;
    }
  }
  function imgOnMouseover(e)
  {
    if (this.xIOO && this.xIOO.complete) {
      this.src = this.xIOO.src;
    }
  }
}
// xInclude, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xInclude(url1, url2, etc)
{
  if (document.getElementById || document.all || document.layers) { // minimum dhtml support required
    var h, f, i, j, a, n, inc;

    for (var i=0; i<arguments.length; ++i) { // loop thru all the url arguments

      h = ''; // html (script or link element) to be written into the document
      f = arguments[i].toLowerCase(); // f is current url in lowercase
      inc = false; // if true the file has already been included

      // Extract the filename from the url

      // Should I extract the file name? What if there are two files with the same name 
      // but in different directories? If I don't extract it what about: '../foo.js' and '../../foo.js' ?

      a = f.split('/');
      n = a[a.length-1]; // the file name

      // loop thru the list to see if this file has already been included
      for (j = 0; j < xIncludeList.length; ++j) {
        if (n == xIncludeList[j]) { // should I use '==' or a string cmp func?
          inc = true;
          break;
        }
      }

      if (!inc) { // if the file has not yet been included

        xIncludeList[xIncludeList.length] = n; // add it to the list of included files

        // is it a .js file?
        if (f.indexOf('.js') != -1) {
          // if nn4 use nn4 versions of certain lib files
          if (document.layers && !window.opera && navigator.vendor != 'KDE' && !document.all) { // use this instead of the sniffer variable
            var c='x_core', e='x_event', d='x_dom', n='_n4';
            if (f.indexOf(c) != -1) { f = f.replace(c, c+n); }
            else if (f.indexOf(e) != -1) { f = f.replace(e, e+n); }
            else if (f.indexOf(d) != -1) { f = f.replace(d, d+n); }
          }
          h = "<script type='text/javascript' src='" + f + "'></script>";
        }

        // else is it a .css file?
        else if (f.indexOf('.css') != -1) { // CSS file
          h = "<link rel='stylesheet' type='text/css' href='" + f + "'>";
        }    
        
        // write the link or script element into the document
        if (h.length) { document.writeln(h); }

      } // end if (!inc)
    } // end outer for
    return true;
  } // end if (min dhtml support)
  return false;
}
// xInnerHtml, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xInnerHtml(e,h)
{
  if(!(e=xGetElementById(e)) || !xStr(e.innerHTML)) return null;
  var s = e.innerHTML;
  if (xStr(h)) {e.innerHTML = h;}
  return s;
}
// xInsertRule, Copyright 2006-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xInsertRule(ss, sel, rule, idx)
{
  if (!(ss=xGetElementById(ss))) return false;
  if (ss.insertRule) { ss.insertRule(sel + "{" + rule + "}", idx); } // DOM
  else if (ss.addRule) { ss.addRule(sel, rule, idx); } // IE
  else return false;
  return true;
}
// xIntersection, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xIntersection(e1, e2, o)
{
  var ix1, iy2, iw, ih, intersect = true;
  var e1x1 = xPageX(e1);
  var e1x2 = e1x1 + xWidth(e1);
  var e1y1 = xPageY(e1);
  var e1y2 = e1y1 + xHeight(e1);
  var e2x1 = xPageX(e2);
  var e2x2 = e2x1 + xWidth(e2);
  var e2y1 = xPageY(e2);
  var e2y2 = e2y1 + xHeight(e2);
  // horizontal
  if (e1x1 <= e2x1) {
    ix1 = e2x1;
    if (e1x2 < e2x1) intersect = false;
    else iw = Math.min(e1x2, e2x2) - e2x1;
  }
  else {
    ix1 = e1x1;
    if (e2x2 < e1x1) intersect = false;
    else iw = Math.min(e1x2, e2x2) - e1x1;
  }
  // vertical
  if (e1y2 >= e2y2) {
    iy2 = e2y2;
    if (e1y1 > e2y2) intersect = false;
    else ih = e2y2 - Math.max(e1y1, e2y1);
  }
  else {
    iy2 = e1y2;
    if (e2y1 > e1y2) intersect = false;
    else ih = e1y2 - Math.max(e1y1, e2y1);
  }
  // intersected rectangle
  if (intersect && typeof(o)=='object') {
    o.x = ix1;
    o.y = iy2 - ih;
    o.w = iw;
    o.h = ih;
  }
  return intersect;
}
// xLeft, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xLeft(e, iX)
{
  if(!(e=xGetElementById(e))) return 0;
  var css=xDef(e.style);
  if (css && xStr(e.style.left)) {
    if(xNum(iX)) e.style.left=iX+'px';
    else {
      iX=parseInt(e.style.left);
      if(isNaN(iX)) iX=xGetComputedStyle(e,'left',1);
      if(isNaN(iX)) iX=0;
    }
  }
  else if(css && xDef(e.style.pixelLeft)) {
    if(xNum(iX)) e.style.pixelLeft=iX;
    else iX=e.style.pixelLeft;
  }
  return iX;
}
xLibrary={version:'4.09',license:'GNU LGPL',url:'http://cross-browser.com/'};
// xLinearScale, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xLinearScale(val,iL,iH,oL,oH)
{
  var m=(oH-oL)/(iH-iL);
  var b=oL-(iL*m);
  return m*val+b;
}
// xLoadScript, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xLoadScript(url)
{
  if (document.createElement && document.getElementsByTagName) {
    var s = document.createElement('script');
    var h = document.getElementsByTagName('head');
    if (s && h.length) {
      s.src = url;
      h[0].appendChild(s);
    }
  }
}
// xMenu1A, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xMenu1A(triggerId, menuId, mouseMargin, slideTime, openEvent)
{
  var isOpen = false;
  var trg = xGetElementById(triggerId);
  var mnu = xGetElementById(menuId);
  if (trg && mnu) {
    xHide(mnu);
    xAddEventListener(trg, openEvent, onOpen, false);
  }
  function onOpen()
  {
    if (!isOpen) {
      xMoveTo(mnu, xPageX(trg), xPageY(trg));
      xShow(mnu);
      xSlideTo(mnu, xPageX(trg), xPageY(trg) + xHeight(trg), slideTime);
      xAddEventListener(document, 'mousemove', onMousemove, false);
      isOpen = true;
    }
  }
  function onMousemove(ev)
  {
    var e = new xEvent(ev);
    if (!xHasPoint(mnu, e.pageX, e.pageY, -mouseMargin) &&
        !xHasPoint(trg, e.pageX, e.pageY, -mouseMargin))
    {
      xRemoveEventListener(document, 'mousemove', onMousemove, false);
      xSlideTo(mnu, xPageX(trg), xPageY(trg), slideTime);
      setTimeout("xHide('" + menuId + "')", slideTime);
      isOpen = false;
    }
  }
} // end xMenu1A
// xMenu1B, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xMenu1B(openTriggerId, closeTriggerId, menuId, slideTime, bOnClick)
{
  xMenu1B.instances[xMenu1B.instances.length] = this;
  var isOpen = false;
  var oTrg = xGetElementById(openTriggerId);
  var cTrg = xGetElementById(closeTriggerId);
  var mnu = xGetElementById(menuId);
  if (oTrg && cTrg && mnu) {
    xHide(mnu);
    if (bOnClick) oTrg.onclick = openOnEvent;
    else oTrg.onmouseover = openOnEvent;
    cTrg.onclick = closeOnClick;
  }
  function openOnEvent()
  {
    if (!isOpen) {
      for (var i = 0; i < xMenu1B.instances.length; ++i) {
        xMenu1B.instances[i].close();
      }
      xMoveTo(mnu, xPageX(oTrg), xPageY(oTrg));
      xShow(mnu);
      xSlideTo(mnu, xPageX(oTrg), xPageY(oTrg) + xHeight(oTrg), slideTime);
      isOpen = true;
    }
  }
  function closeOnClick()
  {
    if (isOpen) {
      xSlideTo(mnu, xPageX(oTrg), xPageY(oTrg), slideTime);
      setTimeout("xHide('" + menuId + "')", slideTime);
      isOpen = false;
    }
  }
  this.close = function()
  {
    closeOnClick();
  }
} // end xMenu1B

xMenu1B.instances = new Array(); // static member of xMenu1B
// xMenu1, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xMenu1(triggerId, menuId, mouseMargin, openEvent)
{
  var isOpen = false;
  var trg = xGetElementById(triggerId);
  var mnu = xGetElementById(menuId);
  if (trg && mnu) {
    xAddEventListener(trg, openEvent, onOpen, false);
  }
  function onOpen()
  {
    if (!isOpen) {
      xMoveTo(mnu, xPageX(trg), xPageY(trg) + xHeight(trg));
      xShow(mnu);
      xAddEventListener(document, 'mousemove', onMousemove, false);
      isOpen = true;
    }
  }
  function onMousemove(ev)
  {
    var e = new xEvent(ev);
    if (!xHasPoint(mnu, e.pageX, e.pageY, -mouseMargin) &&
        !xHasPoint(trg, e.pageX, e.pageY, -mouseMargin))
    {
      xHide(mnu);
      xRemoveEventListener(document, 'mousemove', onMousemove, false);
      isOpen = false;
    }
  }
} // end xMenu1
// xMenu5, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xMenu5(idUL, btnClass, idAutoOpen) // object prototype
{
  // Constructor

  var i, ul, btns, mnu = xGetElementById(idUL);
  btns = xGetElementsByClassName(btnClass, mnu, 'DIV');
  for (i = 0; i < btns.length; ++i) {
    ul = xNextSib(btns[i], 'UL');
    btns[i].xClpsTgt = ul;
    btns[i].onclick = btn_onClick;
    set_display(btns[i], 0);
  }
  if (idAutoOpen) {
    var e = xGetElementById(idAutoOpen);
    while (e && e != mnu) {
      if (e.xClpsTgt) set_display(e, 1);
      while (e && e != mnu && e.nodeName != 'LI') e = e.parentNode;
      e = e.parentNode; // UL
      while (e && !e.xClpsTgt) e = xPrevSib(e);
    }
  }

  // Private
  
  function btn_onClick()
  {
    var thisLi, fc, pUl;
    if (this.xClpsTgt.style.display == 'none') {
      set_display(this, 1);
      // get this label's parent LI
      var li = this.parentNode;
      thisLi = li;
      pUl = li.parentNode; // get this LI's parent UL
      li = xFirstChild(pUl); // get the UL's first LI child
      // close all labels' ULs on this level except for thisLI's label
      while (li) {
        if (li != thisLi) {
          fc = xFirstChild(li);
          if (fc && fc.xClpsTgt) {
            set_display(fc, 0);
          }
        }
        li = xNextSib(li);
      }
    }  
    else {
      set_display(this, 0);
    }
  }

  function set_display(ele, bBlock)
  {
    if (bBlock) {
      ele.xClpsTgt.style.display = 'block';
      ele.innerHTML = '-';
    }
    else {
      ele.xClpsTgt.style.display = 'none';
      ele.innerHTML = '+';
    }
  }

  // Public

  this.onUnload = function()
  {
    for (i = 0; i < btns.length; ++i) {
      btns[i].xClpsTgt = null;
      btns[i].onclick = null;
    }
  }
} // end xMenu5 prototype


// xMoveTo, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xMoveTo(e,x,y)
{
  xLeft(e,x);
  xTop(e,y);
}
// xName, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xName(e)
{
  if (!e) return e;
  else if (e.id && e.id != "") return e.id;
  else if (e.name && e.name != "") return e.name;
  else if (e.nodeName && e.nodeName != "") return e.nodeName;
  else if (e.tagName && e.tagName != "") return e.tagName;
  else return e;
}
// xNextSib, Copyright 2005-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xNextSib(e,t)
{
  e = xGetElementById(e);
  var s = e ? e.nextSibling : null;
  while (s) {
    if (s.nodeType == 1 && (!t || s.nodeName.toLowerCase() == t.toLowerCase())){break;}
    s = s.nextSibling;
  }
  return s;
}
// xNum, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xNum()
{
  for(var i=0; i<arguments.length; ++i){if(isNaN(arguments[i]) || typeof(arguments[i])!='number') return false;}
  return true;
}
// xOffsetLeft, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xOffsetLeft(e)
{
  if (!(e=xGetElementById(e))) return 0;
  if (xDef(e.offsetLeft)) return e.offsetLeft;
  else return 0;
}
// xOffsetTop, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xOffsetTop(e)
{
  if (!(e=xGetElementById(e))) return 0;
  if (xDef(e.offsetTop)) return e.offsetTop;
  else return 0;
}
// xOpacity, Copyright 2006-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xOpacity(e, o)
{
  var set = xDef(o);
  //  if (set && o == 1) o = .9999; // FF1.0.2 but not needed in 1.5
  if(!(e=xGetElementById(e))) return 2; // error
  if (xStr(e.style.opacity)) { // CSS3
    if (set) e.style.opacity = o + '';
    else o = parseFloat(e.style.opacity);
  }
  else if (xStr(e.style.filter)) { // IE5.5+
    if (set) e.style.filter = 'alpha(opacity=' + (100 * o) + ')';
    else if (e.filters && e.filters.alpha) { o = e.filters.alpha.opacity / 100; }
  }
  else if (xStr(e.style.MozOpacity)) { // Gecko before CSS3 support
    if (set) e.style.MozOpacity = o + '';
    else o = parseFloat(e.style.MozOpacity);
  }
  else if (xStr(e.style.KhtmlOpacity)) { // Konquerer and Safari
    if (set) e.style.KhtmlOpacity = o + '';
    else o = parseFloat(e.style.KhtmlOpacity);
  }
  return isNaN(o) ? 1 : o; // if NaN, should this return an error instead of 1?
}
// xPad, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xPad(s,len,c,left)
{
  if(typeof s != 'string') s=s+'';
  if(left) {for(var i=s.length; i<len; ++i) s=c+s;}
  else {for (var i=s.length; i<len; ++i) s+=c;}
  return s;
}
// xPageX, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xPageX(e)
{
  var x = 0;
  e = xGetElementById(e);
  while (e) {
    if (xDef(e.offsetLeft)) x += e.offsetLeft;
    e = xDef(e.offsetParent) ? e.offsetParent : null;
  }
  return x;
}
// xPageY, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xPageY(e)
{
  var y = 0;
  e = xGetElementById(e);
  while (e) {
    if (xDef(e.offsetTop)) y += e.offsetTop;
    e = xDef(e.offsetParent) ? e.offsetParent : null;
  }
  return y;
}
// xParaEq, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

// Animation with Parametric Equations

function xParaEq(e, xExpr, yExpr, totalTime)
{
  if (!(e=xGetElementById(e))) return;
  e.t = 0;
  e.tStep = .008;
  if (!e.timeout) e.timeout = 25;
  e.xExpr = xExpr;
  e.yExpr = yExpr;
  e.slideTime = totalTime;
  var d = new Date();
  e.C = d.getTime();
  if (!e.moving) {e.stop=false; _xParaEq(e);}
}
function _xParaEq(e)
{
  if (!(e=xGetElementById(e))) return;
  var now = new Date();
  var et = now.getTime() - e.C;
  e.t += e.tStep;
  t = e.t;
  if (e.stop) { e.moving = false; }
  else if (!e.slideTime || et < e.slideTime) {
    setTimeout("_xParaEq('"+e.id+"')", e.timeout);
    var p = xParent(e), centerX, centerY;
    centerX = (xWidth(p)/2)-(xWidth(e)/2);
    centerY = (xHeight(p)/2)-(xHeight(e)/2);
    e.xTarget = Math.round((eval(e.xExpr) * centerX) + centerX) + xScrollLeft(p);
    e.yTarget = Math.round((eval(e.yExpr) * centerY) + centerY) + xScrollTop(p);
    xMoveTo(e, e.xTarget, e.yTarget);
    e.moving = true;
  }  
  else {
    e.moving = false;
    if (e.onslideend) e.onslideend();
  }  
}
// xParentChain, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xParentChain(e,delim,bNode)
{
  if (!(e=xGetElementById(e))) return;
  var lim=100, s = "", d = delim || "\n";
  while(e) {
    s += xName(e) + ', ofsL:'+e.offsetLeft + ', ofsT:'+e.offsetTop + d;
    e = xParent(e,bNode);
    if (!lim--) break;
  }
  return s;
}
// xParent, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xParent(e, bNode)
{
  if (!(e=xGetElementById(e))) return null;
  var p=null;
  if (!bNode && xDef(e.offsetParent)) p=e.offsetParent;
  else if (xDef(e.parentNode)) p=e.parentNode;
  else if (xDef(e.parentElement)) p=e.parentElement;
  return p;
}
// xParentNode, Copyright 2005-2007 Olivier Spinelli
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xParentNode( ele, n )
{
  while(ele&&n--){ele=ele.parentNode;}
  return ele;
}
// xPopup, Copyright 2002-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xPopup(sTmrType, uTimeout, sPos1, sPos2, sPos3, sStyle, sId, sUrl)
{
  if (document.getElementById && document.createElement &&
      document.body && document.body.appendChild)
  { 
    // create popup element
    //var e = document.createElement('DIV');
    var e = document.createElement('IFRAME');
    this.ele = e;
    e.id = sId;
    e.style.position = 'absolute';
    e.className = sStyle;
    //e.innerHTML = sHtml;
    e.src = sUrl;
    document.body.appendChild(e);
    xShow(e);
    this.tmr = xTimer.set(sTmrType, this, sTmrType, uTimeout);
    // init
    this.open = false;
    this.margin = 10;
    this.pos1 = sPos1;
    this.pos2 = sPos2;
    this.pos3 = sPos3;
    this.slideTime = 500; // slide time in ms
    this.interval();
  } 
} // end xPopup
// methods
xPopup.prototype.show = function()
{
  this.interval();
};
xPopup.prototype.hide = function()
{
  this.timeout();
};
// timer event listeners
xPopup.prototype.timeout = function() // hide popup
{
  if (this.open) {
    var e = this.ele;
    var pos = xCardinalPosition(e, this.pos3, this.margin, true);
    xSlideTo(e, pos.x, pos.y, this.slideTime);
    setTimeout("xHide('" + e.id + "')", this.slideTime);
    this.open = false;
  }
};
xPopup.prototype.interval = function() // size, position and show popup
{
  if (!this.open) {
    var e = this.ele;
    var pos = xCardinalPosition(e, this.pos1, this.margin, true);
    xMoveTo(e, pos.x, pos.y);
    xShow(e);
    pos = xCardinalPosition(e, this.pos2, this.margin, false);
    xSlideTo(e, pos.x, pos.y, this.slideTime);
    this.open = true;
  }
};
// xPreventDefault, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xPreventDefault(e)
{
  if (e && e.preventDefault) e.preventDefault();
  else if (window.event) window.event.returnValue = false;
}
// xPrevSib, Copyright 2005-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xPrevSib(e,t)
{
  e = xGetElementById(e);
  var s = e ? e.previousSibling : null;
  while (s) {
    if (s.nodeType == 1 && (!t || s.nodeName.toLowerCase() == t.toLowerCase())){break;}
    s = s.previousSibling;
  }
  return s;
}
// xRad, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xRad(deg)
{
  return deg*(Math.PI/180);
}
// xRemoveClass, Copyright 2005-2007 Daniel Frechette
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

/**
 * @param e - Str/Obj - Element id or object
 * @param c - Str - Class name
 * @return  - Bool - true if successful, else false
 */
function xRemoveClass(e, c) {
  e = xGetElementById(e);
  if (!e)
    return false;
  if (xHasClass(e, c))
    e.className = e.className.replace(new RegExp('(^| )'+c+'($| )','g'), '');
  return true;
};
// xRemoveEventListener2, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xRemoveEventListener2(e,eT,eL,cap)
{
  if(!(e=xGetElementById(e))) return;
  eT=eT.toLowerCase();
  if(e==window) {
    if(eT=='resize' && e.xREL) {e.xREL=null; return;}
    if(eT=='scroll' && e.xSEL) {e.xSEL=null; return;}
  }
  if(e.removeEventListener) e.removeEventListener(eT,eL,cap||false);
  else if(e.detachEvent) e.detachEvent('on'+eT,eL);
  else e['on'+eT]=null;
}
// xRemoveEventListener, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xRemoveEventListener(e,eT,eL,cap)
{
  if(!(e=xGetElementById(e)))return;
  eT=eT.toLowerCase();
  if(e.removeEventListener)e.removeEventListener(eT,eL,cap||false);
  else if(e.detachEvent)e.detachEvent('on'+eT,eL);
  else e['on'+eT]=null;
}
// xResizeTo, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xResizeTo(e,w,h)
{
  xWidth(e,w);
  xHeight(e,h);
}
// xScrollLeft, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xScrollLeft(e, bWin)
{
  var offset=0;
  if (!xDef(e) || bWin || e == document || e.tagName.toLowerCase() == 'html' || e.tagName.toLowerCase() == 'body') {
    var w = window;
    if (bWin && e) w = e;
    if(w.document.documentElement && w.document.documentElement.scrollLeft) offset=w.document.documentElement.scrollLeft;
    else if(w.document.body && xDef(w.document.body.scrollLeft)) offset=w.document.body.scrollLeft;
  }
  else {
    e = xGetElementById(e);
    if (e && xNum(e.scrollLeft)) offset = e.scrollLeft;
  }
  return offset;
}
// xScrollTop, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xScrollTop(e, bWin)
{
  var offset=0;
  if (!xDef(e) || bWin || e == document || e.tagName.toLowerCase() == 'html' || e.tagName.toLowerCase() == 'body') {
    var w = window;
    if (bWin && e) w = e;
    if(w.document.documentElement && w.document.documentElement.scrollTop) offset=w.document.documentElement.scrollTop;
    else if(w.document.body && xDef(w.document.body.scrollTop)) offset=w.document.body.scrollTop;
  }
  else {
    e = xGetElementById(e);
    if (e && xNum(e.scrollTop)) offset = e.scrollTop;
  }
  return offset;
}
// xSelect, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xSelect(sId, fnSubOnChange, sMainName, sSubName, bUnder, iMargin) // Object Prototype
{
  // Private Event Listener

  function s1OnChange()
  {
    var io, s2 = this.xSelSub; // 'this' points to s1
    // clear existing
    for (io=0; io<s2.options.length; ++io) {
      s2.options[io] = null;
    }
    // insert new
    var a = this.xSelData, ig = this.selectedIndex;
    for (io=1; io<a[ig].length; ++io) {
      op = new Option(a[ig][io]);
      s2.options[io-1] = op;
    }
  }

  // Constructor Code

  // Check for required browser objects
  var s0 = xGetElementById(sId);
  if (!s0 || !s0.firstChild || !s0.nodeName || !document.createElement || !s0.form || !s0.form.appendChild) {
    return null;
  }
  // Create main category SELECT element
  var s1 = document.createElement('SELECT');
  s1.id = s1.name = sMainName ? sMainName : sId + '_main';
  s1.display = 'block'; // for opera bug?
  s1.style.position = 'absolute';
  s1.xSelObj = this;
  s1.xSelData = new Array();
  // append s1 to s0's form
  s0.form.appendChild(s1);
  // Iterate thru s0 and fill array.
  // For each OPTGROUP, a[og][0] == OPTGROUP label, and...
  // a[og][n] = innerHTML of OPTION n.
  var ig=0, io, op, og, a = s1.xSelData;
  og = s0.firstChild;
  while (og) {
    if (og.nodeName.toLowerCase() == 'optgroup') {
      io = 0;
      a[ig] = new Array();
      a[ig][io] = og.label;
      op = og.firstChild;
      while (op) {
        if (op.nodeName.toLowerCase() == 'option') {
          io++;
          a[ig][io] = op.innerHTML;
        }
        op = op.nextSibling;
      }
      ig++;
    }
    og = og.nextSibling;
  }
  // In s1 insert a new OPTION for each OPTGROUP in s0
  for (ig=0; ig<a.length; ++ig) {
    op = new Option(a[ig][0]);
    s1.options[ig] = op;
  }
  // Create sub-category SELECT element
  var s2 = document.createElement('SELECT');
  s2.id = s2.name = sSubName ? sSubName : sId + '_sub';
  s2.display = 'block'; // for opera bug?
  s2.style.position = 'absolute';
  s2.xSelMain = s1;
  s1.xSelSub = s2;
  // Append s2 to s0's form
  s0.form.appendChild(s2);
  // Add event listeners
  s1.onchange = s1OnChange;
  s2.onchange = fnSubOnChange || null;
  // Hide s0. Position and show s1 where s0 was.
  xHide(s0);
  xMoveTo(s1, xOffsetLeft(s0), xOffsetTop(s0));
  xShow(s1);
  iMargin = iMargin || 0;
  if (bUnder) { // Position s2 under s1.
    xMoveTo(s2, xOffsetLeft(s0), xOffsetTop(s0) + xHeight(s1) + iMargin);
  }
  else { // Position s2 to the right of s1.
    xMoveTo(s2, xOffsetLeft(s0) + xWidth(s1) + iMargin, xOffsetTop(s0));
  }
  xShow(s2);
  // Initialize s2
  s1.onchange();
}


function xSequence(seq) // object prototype
{
  // Private Properties
  var ai = 0; // current action index of seq
  var stop = true;
  var running = false;
  // Private Method
  function runSeq()
  {
    if (stop) {
      running = false;
      return;
    }
    if (this.onslideend) this.onslideend = null; // during a slideend callback
    if (ai >= seq.length) ai = 0;
    var i = ai;
    ++ai;
    if (seq[i][0] != -1) {
      setTimeout(runSeq, seq[i][0]);
    }
    else {
      if (seq[i][2] && seq[i][2][0]) seq[i][2][0].onslideend = runSeq;
    }
    if (seq[i][1]) {
      if (seq[i][2]) seq[i][1].apply(window, seq[i][2]);
      else seq[i][1]();
    }
  }
  // Public Methods
  this.run = function(si)
  {
    if (!running) {
      if (xDef(si) && si >=0 && si < seq.length) ai = si;
      stop = false;
      running = true;
      runSeq();
    }
  };
  this.stop = function()
  {
    stop = true;
  };
  this.onUnload = function() // is this needed? do I have circular refs?
  {                          // this should already have been done above, don't think it's needed
    if (!window.opera) {
      for (var i=0; i<seq.length; ++i) {
        if (seq[i][2] && seq[i][2][0] && seq[i][2][0].onslideend) seq[i][2][0].onslideend = runSeq;
      }
    }
  };
}
// xSetCookie, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xSetCookie(name, value, expire, path)
{
  document.cookie = name + "=" + escape(value) +
                    ((!expire) ? "" : ("; expires=" + expire.toGMTString())) +
                    "; path=" + ((!path) ? "/" : path);
}
// xSetIETitle, Copyright 2003-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xSetIETitle()
{
  var ua = navigator.userAgent.toLowerCase();
  if (!window.opera && navigator.vendor!='KDE' && document.all && ua.indexOf('msie')!=-1 && !document.layers) {
    var i = ua.indexOf('msie') + 1;
    var v = ua.substr(i + 4, 3);
    document.title = 'IE ' + v + ' - ' + document.title;
  }
}
// xShow, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xShow(e) {return xVisibility(e,1);}
// xSlideCornerTo, Copyright 2005-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xSlideCornerTo(e, corner, targetX, targetY, totalTime)
{
  if (!(e=xGetElementById(e))) return;
  if (!e.timeout) e.timeout = 25;
  e.xT = targetX;
  e.yT = targetY;
  e.slideTime = totalTime;
  e.corner = corner.toLowerCase();
  e.stop = false;
  switch(e.corner) { // A = distance, D = initial position
    case 'nw': e.xA = e.xT - xLeft(e); e.yA = e.yT - xTop(e); e.xD = xLeft(e); e.yD = xTop(e); break;
    case 'sw': e.xA = e.xT - xLeft(e); e.yA = e.yT - (xTop(e) + xHeight(e)); e.xD = xLeft(e); e.yD = xTop(e) + xHeight(e); break;
    case 'ne': e.xA = e.xT - (xLeft(e) + xWidth(e)); e.yA = e.yT - xTop(e); e.xD = xLeft(e) + xWidth(e); e.yD = xTop(e); break;
    case 'se': e.xA = e.xT - (xLeft(e) + xWidth(e)); e.yA = e.yT - (xTop(e) + xHeight(e)); e.xD = xLeft(e) + xWidth(e); e.yD = xTop(e) + xHeight(e); break;
    default: alert("xSlideCornerTo: Invalid corner"); return;
  }
  if (e.slideLinear) e.B = 1/e.slideTime;
  else e.B = Math.PI / (2 * e.slideTime); // B = period
  var d = new Date();
  e.C = d.getTime();
  if (!e.moving) _xSlideCornerTo(e);
}

function _xSlideCornerTo(e)
{
  if (!(e=xGetElementById(e))) return;
  var now, seX, seY;
  now = new Date();
  t = now.getTime() - e.C;
  if (e.stop) { e.moving = false; e.stop = false; return; }
  else if (t < e.slideTime) {
    setTimeout("_xSlideCornerTo('"+e.id+"')", e.timeout);

    s = e.B * t;
    if (!e.slideLinear) s = Math.sin(s);
//    if (e.slideLinear) s = e.B * t;
//    else s = Math.sin(e.B * t);

    newX = Math.round(e.xA * s + e.xD);
    newY = Math.round(e.yA * s + e.yD);
  }
  else { newX = e.xT; newY = e.yT; }  
  seX = xLeft(e) + xWidth(e);
  seY = xTop(e) + xHeight(e);
  switch(e.corner) {
    case 'nw': xMoveTo(e, newX, newY); xResizeTo(e, seX - xLeft(e), seY - xTop(e)); break;
    case 'sw': if (e.xT != xLeft(e)) { xLeft(e, newX); xWidth(e, seX - xLeft(e)); } xHeight(e, newY - xTop(e)); break;
    case 'ne': xWidth(e, newX - xLeft(e)); if (e.yT != xTop(e)) { xTop(e, newY); xHeight(e, seY - xTop(e)); } break;
    case 'se': xWidth(e, newX - xLeft(e)); xHeight(e, newY - xTop(e)); break;
    default: e.stop = true;
  }
  //window.status = ('Target: ' + e.xT + ', ' + e.yT);//////debug///////
//  xClip(e, 'auto'); // ?????is this needed? it was used in the original CBE method?????
  e.moving = true;
  if (t >= e.slideTime) {
    e.moving = false;
    if (e.onslideend) e.onslideend();
  }
}
// xSlideTo, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xSlideTo(e, x, y, uTime)
{
  if (!(e=xGetElementById(e))) return;
  if (!e.timeout) e.timeout = 25;
  e.xTarget = x; e.yTarget = y; e.slideTime = uTime; e.stop = false;
  e.yA = e.yTarget - xTop(e); e.xA = e.xTarget - xLeft(e); // A = distance
  if (e.slideLinear) e.B = 1/e.slideTime;
  else e.B = Math.PI / (2 * e.slideTime); // B = period
  e.yD = xTop(e); e.xD = xLeft(e); // D = initial position
  var d = new Date(); e.C = d.getTime();
  if (!e.moving) _xSlideTo(e);
}
function _xSlideTo(e)
{
  if (!(e=xGetElementById(e))) return;
  var now, s, t, newY, newX;
  now = new Date();
  t = now.getTime() - e.C;
  if (e.stop) { e.moving = false; }
  else if (t < e.slideTime) {
    setTimeout("_xSlideTo('"+e.id+"')", e.timeout);

    s = e.B * t;
    if (!e.slideLinear) s = Math.sin(s);
//    if (e.slideLinear) s = e.B * t;
//    else s = Math.sin(e.B * t);

    newX = Math.round(e.xA * s + e.xD);
    newY = Math.round(e.yA * s + e.yD);
    xMoveTo(e, newX, newY);
    e.moving = true;
  }  
  else {
    xMoveTo(e, e.xTarget, e.yTarget);
    e.moving = false;
    if (e.onslideend) e.onslideend();
  }  
}

// xSmartLoadScript, Copyright 2005-2007 Brendan Richards
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xSmartLoadScript(url)
{
  var loadedBefore = false;
  if (typeof(xLoadedList) != "undefined") {
  for (i=0; i<xLoadedList.length; i++) {
    if (xLoadedList[i] == url) {
      loadedBefore = true;
      break;
    }
  }
  }
  if (document.createElement && document.getElementsByTagName && !loadedBefore) {
    var s = document.createElement('script');
    var h = document.getElementsByTagName('head');
    if (s && h.length) {
      s.src = url;
      h[0].appendChild(s);
      if (typeof(xLoadedList) == "undefined") xLoadedList = new Array();
      xLoadedList.push(url);
    }
  }
}
// xSniffer, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

var xOp7Up,xOp6Dn,xIE4Up,xIE4,xIE5,xNN4,xUA=navigator.userAgent.toLowerCase();
if(window.opera){
  var i=xUA.indexOf('opera');
  if(i!=-1){
    var v=parseInt(xUA.charAt(i+6));
    xOp7Up=v>=7;
    xOp6Dn=v<7;
  }
}
else if(navigator.vendor!='KDE' && document.all && xUA.indexOf('msie')!=-1){
  xIE4Up=parseFloat(navigator.appVersion)>=4;
  xIE4=xUA.indexOf('msie 4')!=-1;
  xIE5=xUA.indexOf('msie 5')!=-1;
}
else if(document.layers){xNN4=true;}
xMac=xUA.indexOf('mac')!=-1;
// xSplitter, Copyright 2006-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xSplitter(sSplId, uSplX, uSplY, uSplW, uSplH, bHorizontal, uBarW, uBarPos, uBarLimit, bBarEnabled, uSplBorderW, oSplChild1, oSplChild2)
{
  // Private

  var pane1, pane2, splW, splH;
  var splEle, barPos, barLim, barEle;

  function barOnDrag(ele, dx, dy)
  {
    var bp;
    if (bHorizontal)
    {
        bp = barPos + dx;
        if (bp < uBarLimit || bp > splW - uBarLimit) { return; }
        xWidth(pane1, xWidth(pane1) + dx);
        xLeft(barEle, xLeft(barEle) + dx);
        xWidth(pane2, xWidth(pane2) - dx);
        xLeft(pane2, xLeft(pane2) + dx);
        barPos = bp;
    }
    else
    {
        bp = barPos + dy;
        if (bp < uBarLimit || bp > splH - uBarLimit) { return; }
        xHeight(pane1, xHeight(pane1) + dy);
        xTop(barEle, xTop(barEle) + dy);
        xHeight(pane2, xHeight(pane2) - dy);
        xTop(pane2, xTop(pane2) + dy);
        barPos = bp;
    }
    if (oSplChild1) { oSplChild1.paint(xWidth(pane1), xHeight(pane1)); }
    if (oSplChild2) { oSplChild2.paint(xWidth(pane2), xHeight(pane2)); }
  }

  // Public

  this.paint = function(uNewW, uNewH, uNewBarPos, uNewBarLim) // uNewBarPos and uNewBarLim are optional
  {
    if (uNewW == 0) { return; }
    var w1, h1, w2, h2;
    splW = uNewW;
    splH = uNewH;
    barPos = uNewBarPos || barPos;
    barLim = uNewBarLim || barLim;
    xMoveTo(splEle, uSplX, uSplY);
    xResizeTo(splEle, uNewW, uNewH);
    if (bHorizontal)
    {
      w1 = barPos;
      h1 = uNewH - 2 * uSplBorderW;
      w2 = uNewW - w1 - uBarW - 2 * uSplBorderW;
      h2 = h1;
      xMoveTo(pane1, 0, 0);
      xResizeTo(pane1, w1, h1);
      xMoveTo(barEle, w1, 0);
      xResizeTo(barEle, uBarW, h1);
      xMoveTo(pane2, w1 + uBarW, 0);
      xResizeTo(pane2, w2, h2);
    }
    else
    {
      w1 = uNewW - 2 * uSplBorderW;;
      h1 = barPos;
      w2 = w1;
      h2 = uNewH - h1 - uBarW - 2 * uSplBorderW;
      xMoveTo(pane1, 0, 0);
      xResizeTo(pane1, w1, h1);
      xMoveTo(barEle, 0, h1);
      xResizeTo(barEle, w1, uBarW);
      xMoveTo(pane2, 0, h1 + uBarW);
      xResizeTo(pane2, w2, h2);
    }
    if (oSplChild1)
    {
      pane1.style.overflow = 'hidden';
      oSplChild1.paint(w1, h1);
    }
    if (oSplChild2)
    {
      pane2.style.overflow = 'hidden';
      oSplChild2.paint(w2, h2);
    }
  };

  // Constructor

  splEle = xGetElementById(sSplId); // we assume the splitter has 3 DIV children and in this order:
  pane1 = xFirstChild(splEle, 'DIV');
  pane2 = xNextSib(pane1, 'DIV');
  barEle = xNextSib(pane2, 'DIV');
  //  --- slightly dirty hack
  pane1.style.zIndex = 2;
  pane2.style.zIndex = 2;
  barEle.style.zIndex = 1;
  // ---
  barPos = uBarPos;
  barLim = uBarLimit;
  this.paint(uSplW, uSplH);
  if (bBarEnabled)
  {
    xEnableDrag(barEle, null, barOnDrag, null);
    barEle.style.cursor = bHorizontal ? 'e-resize' : 'n-resize';
  }
  splEle.style.visibility = 'visible';

} // end xSplitter
// xStopPropagation, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xStopPropagation(evt)
{
  if (evt && evt.stopPropagation) evt.stopPropagation();
  else if (window.event) window.event.cancelBubble = true;
}
// xStrEndsWith, Copyright 2004-2007 Olivier Spinelli
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xStrEndsWith( s, end )
{
  if( !xStr(s,end) ) return false;
  var l = s.length;
  var r = l - end.length;
  if( r > 0 ) return s.substring( r, l ) == end;
  return s == end;
}
// xStr, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xStr(s)
{
  for(var i=0; i<arguments.length; ++i){if(typeof(arguments[i])!='string') return false;}
  return true;
}
// xStrReplaceEnd, Copyright 2004-2007 Olivier Spinelli
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xStrReplaceEnd( s, newEnd )
{
  if( !xStr(s,newEnd) ) return s;
  var l = s.length;
  var r = l - newEnd.length;
  if( r > 0 ) return s.substring( 0, r )+newEnd;
  return newEnd;
}
// xStrStartsWith, Copyright 2004-2007 Olivier Spinelli
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xStrStartsWith( s, beg )
{
  if( !xStr(s,beg) ) return false;
  var l = s.length;
  var r = beg.length;
  if( r > l ) return false;
  if( r == l ) return s.substring( 0, r ) == beg;
  return s == beg;
}
// xTableCellVisibility, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xTableCellVisibility(bShow, sec, nRow, nCol)
{
  sec = xGetElementById(sec);
  if (sec && nRow < sec.rows.length && nCol < sec.rows[nRow].cells.length) {
    sec.rows[nRow].cells[nCol].style.visibility = bShow ? 'visible' : 'hidden';
  }
}
// xTableColDisplay, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xTableColDisplay(bShow, sec, nCol)
{
  var r;
  sec = xGetElementById(sec);
  if (sec && nCol < sec.rows[0].cells.length) {
    for (r = 0; r < sec.rows.length; ++r) {
      sec.rows[r].cells[nCol].style.display = bShow ? '' : 'none';
    }
  }
}
// xTableCursor2, Copyright 2007 Stephen Hulme
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xTableCursor2(id, hov, sel) // object prototype
{
  var tbl = xGetElementById(id);
  if (tbl) {
    xTableIterate(tbl, init);
  }
  function init(obj, isRow)
  {
    if (isRow) {
      obj.onmouseover = trOver;
      obj.onmouseout = trOut;
    }
    else {
      obj.onmouseover = tdOver;
      obj.onmouseout = tdOut;
    }
  }
  this.unload = function() { xTableIterate(tbl, done); };
  function done(o) { o.onmouseover = o.onmouseout = null; }
  function trOver() { this.className += " " + hov; }
  function trOut() { this.className = this.className.replace(hov,""); }
  function tdOver() { this.className += " " + sel; }
  function tdOut() { this.className = this.className.replace(sel,""); }
}
// xTableCursor, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xTableCursor(id, inh, def, hov, sel) // object prototype
{
  var tbl = xGetElementById(id);
  if (tbl) {
    xTableIterate(tbl, init);
  }
  function init(obj, isRow)
  {
    if (isRow) {
      obj.className = def;
      obj.onmouseover = trOver;
      obj.onmouseout = trOut;
    }
    else {
      obj.className = inh;
      obj.onmouseover = tdOver;
      obj.onmouseout = tdOut;
    }
  }
  this.unload = function() { xTableIterate(tbl, done); };
  function done(o) { o.onmouseover = o.onmouseout = null; }
  function trOver() { this.className = hov; }
  function trOut() { this.className = def; }
  function tdOver() { this.className = sel; }
  function tdOut() { this.className = inh; }
}
// xTableHeaderFixed, Copyright 2006-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xTableHeaderFixed(fixedContainerId, fixedTableClass, fakeBodyId, tableBorder, thBorder)
{
  // Private Property
  var tables = [];
  // Private Event Listener
  function onEvent(e) // handles scroll and resize events
  {
    e = e || window.event;
    var r = e.type == 'resize' ? true : false;
    for (var i = 0; i < tables.length; ++i) {
      scroll(tables[i], r);
    }
  }
  // Private Methods
  function scroll(t, bResize)
  {
    if (!t) { return; }
    var fhc = xGetElementById(fixedContainerId); // for IE6
    var fh = xGetElementById(t.fixedHeaderId);
    var thead = t.tHead;
    var st, sl, thy = xPageY(thead);
    /*@cc_on
    @if (@_jscript_version == 5.6) // IE6
    st = xGetElementById(fakeBodyId).scrollTop;
    sl = xGetElementById(fakeBodyId).scrollLeft;
    @else @*/
    st = xScrollTop();
    sl = xScrollLeft();
    /*@end @*/
    var th = xHeight(t);
    var tw = xWidth(t);
    var ty = xPageY(t);
    var tx = xPageX(t);
    var fhh = xHeight(fh);
    if (bResize) {
      xWidth(fh, tw + 2*tableBorder);
      var th1 = xGetElementsByTagName('th', t);
      var th2 = xGetElementsByTagName('th', fh);
      for (var i = 0; i < th1.length; ++i) {
        xWidth(th2[i], xWidth(th1[i]) + thBorder);
      }
    }
    xLeft(fh, tx - sl);
    if (st <= thy || st > ty + th - fhh) {
      if (fh.style.visibility != 'hidden') {
        fh.style.visibility = 'hidden';
        fhc.style.visibility = 'hidden'; // for IE6
      }
    }
    else {
      if (fh.style.visibility != 'visible') {
        fh.style.visibility = 'visible';
        fhc.style.visibility = 'visible'; // for IE6
      }
    }
  }
  function init()
  {
    var i, tbl, h, t, con;
    if (null == (con = xGetElementById(fixedContainerId))) {
      con = document.createElement('div');
      con.id = fixedContainerId;
      document.body.appendChild(con);
    }
    for (i = 0; i < tables.length; ++i) {
      tbl = tables[i];
      h = tbl.tHead;
      if (h) {
        t = document.createElement('table');
        t.className = fixedTableClass;
        t.appendChild(h.cloneNode(true));
        t.id = tbl.fixedHeaderId = 'xtfh' + i;
        con.appendChild(t);
      }
      else {
        tables[i] = null; // ignore tables with no thead
      }
    }
    con.style.visibility = 'hidden'; // for IE6
  }
  // Public Method
  this.unload = function()
  {
    for (var i = 0; i < tables.length; ++i) {
      tables[i] = null;
    }
  };
  // Constructor Code
  var i, lst;
  if (arguments.length > 5) { // we've been passed a list of IDs and/or Element objects
    i = 5;
    lst = arguments;
  }
  else { // make a list of all tables
    i = 0;
    lst = xGetElementsByTagName('table');
  }
  for (; i < lst.length; ++i) {
    tables[i] = xGetElementById(lst[i]);
  }
  init();
  onEvent({type:'resize'});
  /*@cc_on
  @if (@_jscript_version == 5.6) // IE6
  xAddEventListener(fakeBodyId, 'scroll', onEvent, false);
  @else @*/
  xAddEventListener(window, 'scroll', onEvent, false);
  /*@end @*/
  xAddEventListener(window, 'resize', onEvent, false);
} // end xTableHeaderFixed
// xTableIterate, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xTableIterate(sec, fnCallback, data)
{
  var r, c;
  sec = xGetElementById(sec);
  if (!sec || !fnCallback) { return; }
  for (r = 0; r < sec.rows.length; ++r) {
    if (false == fnCallback(sec.rows[r], true, r, c, data)) { return; }
    for (c = 0; c < sec.rows[r].cells.length; ++c) {
      if (false == fnCallback(sec.rows[r].cells[c], false, r, c, data)) { return; }
    }
  }
}

// xTable, Copyright 2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xTable(sTableId, sRoot, sCC, sFR, sFRI, sRCell, sFC, sFCI, sCCell, sTC, sCellT)
{
  var i, ot, cc=null, fcw, frh, root, fr, fri, fc, fci, tc;
  var e, t, tr, a, alen, tmr=null;

  ot = xGetElementById(sTableId); // original table
  if (!ot || !document.createElement || !document.appendChild || !ot.deleteCaption || !ot.deleteTHead) {
    return null;
  }
  fcw = xWidth(ot.rows[1].cells[0]); // get first column width before altering ot
  frh = xHeight(ot.rows[0]); // get first row height before altering ot
  root = document.createElement('div'); // overall container
  root.className = sRoot;
  fr = document.createElement('div'); // frozen-row container
  fr.className = sFR;
  fri = document.createElement('div'); // frozen-row inner container, for column headings
  fri.className = sFRI;
  fr.appendChild(fri);
  root.appendChild(fr);
  fc = document.createElement('div'); // frozen-column container
  fc.className = sFC;
  fci = document.createElement('div'); // frozen-column inner container, for row headings
  fci.className = sFCI;
  fc.appendChild(fci);
  root.appendChild(fc);
  tc = document.createElement('div'); // table container, contains ot
  tc.className = sTC;
  root.appendChild(tc);
  if (ot.caption) {
    cc = document.createElement('div'); // caption container
    cc.className = sCC;
    cc.appendChild(ot.caption.firstChild); // only gets first child
    root.appendChild(cc);
    ot.deleteCaption();
  }
  // Create fr cells (column headings)
  a = ot.rows[0].cells;
  alen = a.length;
  for (i = 1; i < alen; ++i) {
    e = document.createElement('div');
    e.className = sRCell;
    t = document.createElement('table');
    t.className = sCellT;
    tr = t.insertRow(0);
    tr.appendChild(a[1]);
    e.appendChild(t);
    fri.appendChild(e);
  }
  if (ot.tHead) {
    ot.deleteTHead();
  }
  // Create fc cells (row headings)
  a = ot.rows;
  alen = a.length;
  for (i = 0; i < alen; ++i) {
    e = document.createElement('div');
    e.className = sCCell;
    t = document.createElement('table');
    t.className = sCellT;
    tr = t.insertRow(0);
    tr.appendChild(a[i].cells[0]);
    e.appendChild(t);
    fci.appendChild(e);
  }
  ot = ot.parentNode.replaceChild(root, ot);
  tc.appendChild(ot);

  resize();
  root.style.visibility = 'visible';
  xAddEventListener(tc, 'scroll', onScroll, false);
  xAddEventListener(window, 'resize', onResize, false);

  function onScroll()
  {
    xLeft(fri, -tc.scrollLeft);
    xTop(fci, -tc.scrollTop);
  }
  function onResize()
  {
    if (!tmr) {
      tmr = setTimeout(
        function() {
          resize();
          tmr=null;
        }, 500);
    }
  }
  function resize()
  {
    var sum = 0, cch = 0, w, h;
    // caption container
    if (cc) {
      cch = xHeight(cc);
      xMoveTo(cc, 0, 0);
      xWidth(cc, xWidth(root));
    }
    // frozen row
    xMoveTo(fr, fcw, cch);
    xResizeTo(fr, xWidth(root) - fcw, frh);
    xMoveTo(fri, 0, 0);
    xResizeTo(fri, xWidth(ot), frh);
    // frozen col
    xMoveTo(fc, 0, cch + frh);
    xResizeTo(fc, fcw, xHeight(root) - cch);
    xMoveTo(fci, 0, 0);
    xResizeTo(fci, fcw, xHeight(ot));
    // table container
    xMoveTo(tc, fcw, cch + frh);
    xWidth(tc, xWidth(root) - fcw - 1);
    xHeight(tc, xHeight(root) - cch - frh - 1);
    // size and position fr cells
    a = ot.rows[0].cells;
    e = xFirstChild(fri, 'div');
    for (i = 0; i < a.length; ++i) {
      xMoveTo(e, sum, 0);
      w = xWidth(e, xWidth(a[i]));
      h = xHeight(e, frh);
      sum += w;
      xResizeTo(xFirstChild(e, 'table'), w, h);//////////
      e = xNextSib(e, 'div');
    }
    // size and position fc cells
    sum = 0;
    a = ot.rows;
    e = xFirstChild(fci, 'div');
    for (i = 0; i < a.length; ++i) {
      xMoveTo(e, 0, sum);
      w = xWidth(e, fcw);
      h = xHeight(e, xHeight(a[i]));
      sum += h;
      xResizeTo(xFirstChild(e, 'table'), w, h);//////////
      e = xNextSib(e, 'div');
    }
    onScroll();
  } // end resize
} // end xTable
// xTableRowDisplay, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xTableRowDisplay(bShow, sec, nRow)
{
  sec = xGetElementById(sec);
  if (sec && nRow < sec.rows.length) {
    sec.rows[nRow].style.display = bShow ? '' : 'none';
  }
}
// xTableSync, Copyright 2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xTableSync(sT1Id, sT2Id, sEvent, fn)
{
  var t1 = xGetElementById(sT1Id);
  var t2 = xGetElementById(sT2Id);
  sEvent = 'on' + sEvent.toLowerCase();
  t1[sEvent] = t2[sEvent] = function(e)
  {
    e = e || window.event;
    var t = e.target || e.srcElement;
    while (t && t.nodeName.toLowerCase() != 'td') {
      t = t.parentNode;
    }
    if (t) {
      var r = t.parentNode.sectionRowIndex, c = t.cellIndex; // this may not be very cross-browser
      var tbl = xGetElementById(this.id == sT1Id ? sT2Id : sT1Id); // 'this' points to a table
      fn(t, tbl.rows[r].cells[c]);
    }
  };
  // r2
  t1 = t2 = null; // Does this remove the circular refs even tho the closure remains?
  /*
  xAddEventListener(window, 'unload',
    function() {
      t1[sEvent] = t2[sEvent] = null;
      t1 = t2 = null;
    }, false
  );
  */
}
// xTabPanelGroup, Copyright 2005-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xTabPanelGroup(id, w, h, th, clsTP, clsTG, clsTD, clsTS) // object prototype
{
  // Private Methods

  function onClick() //r7
  {
    paint(this);
    return false;
  }
  function onFocus() //r7
  {
    paint(this);
  }
  function paint(tab)
  {
    tab.className = clsTS;
    xZIndex(tab, highZ++);
    xDisplay(panels[tab.xTabIndex], 'block'); //r6
    if (selectedIndex != tab.xTabIndex) {
      xDisplay(panels[selectedIndex], 'none'); //r6
      tabs[selectedIndex].className = clsTD;
      selectedIndex = tab.xTabIndex;
    }
  }

  // Private Properties

  var panelGrp, tabGrp, panels, tabs, highZ, selectedIndex;
  
  // Public Methods

  this.select = function(n) //r7
  {
    if (n && n <= tabs.length) {
      var t = tabs[n-1];
      if (t.focus) t.focus();
      else t.onclick();
    }
  };
  this.onUnload = function()
  {
    if (!window.opera) for (var i = 0; i < tabs.length; ++i) {tabs[i].onfocus = tabs[i].onclick = null;}
  };
  this.onResize = function(newW, newH) //r9
  {
    var x = 0, i;
    // [r9
    if (newW) {
      w = newW;
      xWidth(panelGrp, w);
    }
    else w = xWidth(panelGrp);
    if (newH) {
      h = newH;
      xHeight(panelGrp, h);
    }
    else h = xHeight(panelGrp);
    // r9]
    xResizeTo(tabGrp[0], w, th);
    xMoveTo(tabGrp[0], 0, 0);
    w -= 2; // remove border widths
    var tw = w / tabs.length;
    for (i = 0; i < tabs.length; ++i) {
      xResizeTo(tabs[i], tw, th); 
      xMoveTo(tabs[i], x, 0);
      x += tw;
      tabs[i].xTabIndex = i;
      tabs[i].onclick = onClick;
      tabs[i].onfocus = onFocus; //r7
      xDisplay(panels[i], 'none'); //r6
      xResizeTo(panels[i], w, h - th - 2); // -2 removes border widths
      xMoveTo(panels[i], 0, th);
    }
    highZ = i;
    tabs[selectedIndex].onclick(); //r9
  };

  // Constructor Code

  panelGrp = xGetElementById(id);
  if (!panelGrp) { return null; }
  panels = xGetElementsByClassName(clsTP, panelGrp);
  tabs = xGetElementsByClassName(clsTD, panelGrp);
  tabGrp = xGetElementsByClassName(clsTG, panelGrp);
  if (!panels || !tabs || !tabGrp || panels.length != tabs.length || tabGrp.length != 1) { return null; }
  selectedIndex = 0;
  this.onResize(w, h); //r9
}
// xTimer, Copyright 2003-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xTimerMgr()
{
  this.tmr = null;
  this.timers = new Array();
}
// xTimerMgr Methods
xTimerMgr.prototype.set = function(type, obj, sMethod, uTime, data) // type: 'interval' or 'timeout'
{
  return (this.timers[this.timers.length] = new xTimerObj(type, obj, sMethod, uTime, data));
};
xTimerMgr.prototype.run = function()
{
  var i, t, d = new Date(), now = d.getTime();
  for (i = 0; i < this.timers.length; ++i) {
    t = this.timers[i];
    if (t && t.running) {
      t.elapsed = now - t.time0;
      if (t.elapsed >= t.preset) { // timer event on t
        t.obj[t.mthd](t); // pass listener this xTimerObj
        if (t.type.charAt(0) == 'i') { t.time0 = now; }
        else { t.stop(); }
      }  
    }
  }
};
xTimerMgr.prototype.tick = function(t) // set the timers' resolution
{
  if (this.tmr) clearInterval(this.tmr);
  this.tmr = setInterval('xTimer.run()', t);
};
// Object Prototype used only by xTimerMgr
function xTimerObj(type, obj, mthd, preset, data)
{
  // Public Properties
  this.data = data;
  // Read-only Properties
  this.type = type; // 'interval' or 'timeout'
  this.obj = obj;
  this.mthd = mthd; // string
  this.preset = preset;
  this.reset();
} // end xTimerObj constructor
// xTimerObj Methods
xTimerObj.prototype.stop = function() { this.running = false; };
xTimerObj.prototype.start = function() { this.running = true; }; // continue after a stop
xTimerObj.prototype.reset = function()
{
  var d = new Date();
  this.time0 = d.getTime();
  this.elapsed = 0;
  this.running = true;
};
var xTimer = new xTimerMgr(); // applications assume global name is 'xTimer'
xTimer.tmr = setInterval('xTimer.run()', 25);
// xTimes, Copyright 2006-2007 Daniel Frechette
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

/**
 * Call a function n times.
 * @param n - Int  - Number of times f is called
 * @param f - Func - Function to execute (can accept an index value from 0 to n-1)
 * @param s - Int  - Start index (0 if null or not present)
 * @return Nothing
 */
function xTimes(n, f, s) {
  s = s || 0;
  n = n + s;
  for (var i=s; i < n; i++)
    f(i);
};
// xToggleClass, Copyright 2005-2007 Daniel Frechette
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

/* Added by DF, 2005-10-11
 * Toggles a class name on or off for an element
 */
function xToggleClass(e, c) {
  if (!(e = xGetElementById(e)))
    return null;
  if (!xRemoveClass(e, c) && !xAddClass(e, c))
    return false;
  return true;
}
// xTooltipGroup, Copyright 2002-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xTooltipGroup(grpClassOrIdList, tipClass, origin, xOffset, yOffset, textList)
{
  //// Properties

  this.c = tipClass;
  this.o = origin;
  this.x = xOffset;
  this.y = yOffset;

  //// Constructor Code

  var i, tips;
  if (xStr(grpClassOrIdList)) {
    tips = xGetElementsByClassName(grpClassOrIdList);
    for (i = 0; i < tips.length; ++i) {
      tips[i].xTooltip = this;
    }
  }
  else {
    tips = new Array();
    for (i = 0; i < grpClassOrIdList.length; ++i) {
      tips[i] = xGetElementById(grpClassOrIdList[i]);
      if (!tips[i]) {
        alert('Element not found for id = ' + grpClassOrIdList[i]);
      }  
      else {
        tips[i].xTooltip = this;
        tips[i].xTooltipText = textList[i];
      }
    }
  }
  if (!xTooltipGroup.tipEle) { // only execute once
    var te = document.createElement("div");
    if (te) {
      te.setAttribute('id', 'xTooltipElement');
      te.setAttribute('style', 'position:absolute;visibility:hidden;');
      xTooltipGroup.tipEle = document.body.appendChild(te);
      xAddEventListener(document, 'mousemove', xTooltipGroup.docOnMousemove, false);
    }
  }
} // end xTooltipGroup ctor

//// Static Properties

xTooltipGroup.trgEle = null; // currently active trigger
xTooltipGroup.tipEle = null; // the tooltip element (all groups use the same element)

//// Static Method

xTooltipGroup.docOnMousemove = function(oEvent)
{
  var o, e = new xEvent(oEvent);
  if (e.target && (o = e.target.xTooltip)) {
    o.show(e.target, e.pageX, e.pageY);
  }
  else if (xTooltipGroup.trgEle) {
    xTooltipGroup.trgEle.xTooltip.hide();
  }
};

//// xTooltipGroup Public Methods

xTooltipGroup.prototype.show = function(trigEle, mx, my)
{
  if (xTooltipGroup.trgEle != trigEle) { // if not active or moved to an adjacent trigger
    xTooltipGroup.tipEle.className = trigEle.xTooltip.c;
    xTooltipGroup.tipEle.innerHTML = trigEle.xTooltipText ? trigEle.xTooltipText : trigEle.title;
    xTooltipGroup.trgEle = trigEle;
  }  
  var x, y, tipW, trgW, trgX;
  tipW = xWidth(xTooltipGroup.tipEle);
  trgW = xWidth(trigEle);
  trgX = xPageX(trigEle);
  switch(this.o) {
    case 'right':
      if (trgX + this.x + trgW + tipW < xClientWidth()) { x = trgX + this.x + trgW; }
      else { x = trgX - tipW - this.x; }
      y = xPageY(trigEle) + this.y;
      break;
    case 'top':
      x = trgX + this.x;
      y = xPageY(trigEle) - xHeight(trigEle) + this.y;
      break;
    case 'mouse':
      if (mx + this.x + tipW < xClientWidth()) { x = mx + this.x; }
      else { x = mx - tipW - this.x; }
      y = my + this.y;
      break;
  }
  xMoveTo(xTooltipGroup.tipEle, x, y);
  xShow(xTooltipGroup.tipEle);
};

xTooltipGroup.prototype.hide = function()
{
  xMoveTo(xTooltipGroup.tipEle, -1000, -1000);
  xTooltipGroup.trgEle = null;
};
// xTop, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xTop(e, iY)
{
  if(!(e=xGetElementById(e))) return 0;
  var css=xDef(e.style);
  if(css && xStr(e.style.top)) {
    if(xNum(iY)) e.style.top=iY+'px';
    else {
      iY=parseInt(e.style.top);
      if(isNaN(iY)) iY=xGetComputedStyle(e,'top',1);
      if(isNaN(iY)) iY=0;
    }
  }
  else if(css && xDef(e.style.pixelTop)) {
    if(xNum(iY)) e.style.pixelTop=iY;
    else iY=e.style.pixelTop;
  }
  return iY;
}
// xTraverseDocumentStyleSheets, Copyright 2006-2007 Ivan Pepelnjak (www.zaplana.net)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

//
// xTraverseDocumentStyleSheets(callback)
//   traverses all stylesheets attached to a document (linked as well as internal)
//
function xTraverseDocumentStyleSheets(cb) {
  var ssList = document.styleSheets; if (!ssList) return undefined;

  for (i = 0; i < ssList.length; i++) {
    var ss = ssList[i] ; if (! ss) continue;
    if (xTraverseStyleSheet(ss,cb)) return true;
  }
  return false;
}
// xTraverseStyleSheet, Copyright 2006-2007 Ivan Pepelnjak (www.zaplana.net)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

//
// xTraverseStyleSheet (stylesheet, callback)
//   traverses all rules in the stylesheet, calling callback function on each rule.
//   recursively handles stylesheets imported with @import CSS directive
//   stops when the callback function returns true (it has found what it's been looking for)
//
// returns:
//   undefined - problems with CSS-related objects
//   true      - callback function returned true at least once
//   false     - callback function always returned false
//
function xTraverseStyleSheet(ss,cb) {
  if (!ss) return false;
  var rls = xGetCSSRules(ss) ; if (!rls) return undefined ;
  var result;

  for (var j = 0; j < rls.length; j++) {
    var cr = rls[j];
    if (cr.selectorText) { result = cb(cr); if (result) return true; }
    if (cr.type && cr.type == 3 && cr.styleSheet) xTraverseStyleSheet(cr.styleSheet,cb);
  }
  if (ss.imports) {
    for (var j = 0 ; j < ss.imports.length; j++) {
      if (xTraverseStyleSheet(ss.imports[j],cb)) return true;
    }
  }
  return false;
}
// xTreeMenu, Copyright 2006-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xTreeMenu(sUlId, sMainUlClass, sSubUlClass, sLblLiClass, sItmLiClass, sPlusImg, sMinusImg, sImgClass, sImgWidth) // Object Prototype
{
  // Public Property
  this.id = sUlId;
  // Private Event Listener
  function onclick()
  {
    if (this.xtmChildUL) { // 'this' points to the A element clicked
      var s, uls = this.xtmChildUL.style;
      if (uls.display != 'block') { // close sub-menu
        s = sMinusImg;
        uls.display = 'block';
        xWalkUL(this.xtmParentUL, this.xtmChildUL,
          function(p,li,c,d) {
            if (c && c != d && c.style.display != 'none') {
              if (sPlusImg) {
                var a = xFirstChild(li,'a');
                xFirstChild(a,'img').src = sPlusImg;
              }
              c.style.display = 'none';
            }
            return true;
          }
        );
      }
      else { // open sub-menu
        s = sPlusImg;
        uls.display = 'none';
      }
      if (sPlusImg) {
        xFirstChild(this,'img').src = s;
      }
      return false;
    }
    return true;
  }
  // Constructor Code
  var ul = xGetElementById(sUlId);
  ul.className = sMainUlClass;
  xWalkUL(ul, null,
    function(p,li,c) {
      var liCls = sItmLiClass;
      var a = xFirstChild(li,'a');
      if (a) {
        var m = 'Click to toggle sub-menu';
        if (c) { // this LI is a label which presedes the submenu c
          if (sPlusImg) {
            // insert the image as the firstChild of the A element
            var i = document.createElement('img');
            i.title = m;
            a.insertBefore(i, a.firstChild);
            i.src = sPlusImg;
            i.className = sImgClass;
          }
          liCls = sLblLiClass;
          c.className = sSubUlClass;
          c.style.display = 'none';
          a.title = m;
          a.xtmParentUL = p;
          a.xtmChildUL = c;
          a.onclick = onclick;
        }
        else if (sPlusImg) { // this LI is not a label but is an item
          // if we are inserting images in label As then give A items left padding equal to the image width
          a.style.paddingLeft = sImgWidth;
        }
      }
      li.className = liCls;
      return true;
    }
  );
} // end prototype
// Public Methods
xTreeMenu.prototype.unload = function()
{
  xWalkUL(xGetElementById(this.id), null,
    function(p,li,c) {
      var a = xFirstChild(li,'a');
      if (a && c) {
        a.xtmParentUL = null;
        a.xtmChildUL = null;
        a.onclick = null;
      }
      return true;
    }
  );
};
/* not yet finished
xTreeMenu.prototype.open = function(s)
{
  var i, n, a = s.split(',');
  var ul = xGetElementById(this.id);
  n = parseInt(a[0]);
  for (i = 0; i < n; ++i) {

  }
};
*/
// xTriStateImage, Copyright 2004-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xTriStateImage(idOut, urlOver, urlDown, fnUp) // Object Prototype
{
  var img;
  // Downgrade Detection
  if (typeof Image != 'undefined' && document.getElementById) {
    img = document.getElementById(idOut);
    if (img) {
      // Constructor Code
      var urlOut = img.src;
      var i = new Image();
      i.src = urlOver;
      i = new Image();
      i.src = urlDown;
      // Event Listeners (closure)
      img.onmouseover = function() { this.src = urlOver; };
      img.onmouseout = function() { this.src = urlOut; };
      img.onmousedown = function() { this.src = urlDown; };
      img.onmouseup = function()
      {
        this.src = urlOver;
        if (fnUp) {
          fnUp();
        }
      };
    }
  }
  // Destructor Method
  this.onunload = function()
  {
    if (!window.opera && img) { // Remove any circular references for IE
      img.onmouseover = img.onmouseout = img.onmousedown = null;
      img = null;
    }
  };    
}
// xVisibility, Copyright 2003-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xVisibility(e, bShow)
{
  if(!(e=xGetElementById(e))) return null;
  if(e.style && xDef(e.style.visibility)) {
    if (xDef(bShow)) e.style.visibility = bShow ? 'visible' : 'hidden';
    return e.style.visibility;
  }
  return null;
}

//function xVisibility(e,s)
//{
//  if(!(e=xGetElementById(e))) return null;
//  var v = 'visible', h = 'hidden';
//  if(e.style && xDef(e.style.visibility)) {
//    if (xDef(s)) {
//      // try to maintain backwards compatibility (???)
//      if (xStr(s)) e.style.visibility = s;
//      else e.style.visibility = s ? v : h;
//    }
//    return e.style.visibility;
//    // or...
//    // if (e.style.visibility.length) return e.style.visibility;
//    // else return xGetComputedStyle(e, 'visibility');
//  }
//  else if (xDef(e.visibility)) { // NN4
//    if (xDef(s)) {
//      // try to maintain backwards compatibility
//      if (xStr(s)) e.visibility = (s == v) ? 'show' : 'hide';
//      else e.visibility = s ? v : h;
//    }
//    return (e.visibility == 'show') ? v : h;
//  }
//  return null;
//}
// xWalkToFirst, Copyright 2005-2007 Olivier Spinelli
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xWalkToFirst( oNode, fnVisit, skip, data )
{
  var r = null;
  while(oNode)
  {
    if(oNode.nodeType==1&&oNode!=skip){r=fnVisit(oNode,data);if(r)return r;}
    var n=oNode;
    while(n=n.previousSibling){if(n!=skip){r=xWalkTreeRev(n,fnVisit,skip,data);if(r)return r;}}
    oNode=oNode.parentNode;
  }
  return r;
}
// xWalkToLast, Copyright 2005-2007 Olivier Spinelli
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xWalkToLast( oNode, fnVisit, skip, data )
{
  var r = null;
  if( oNode )
  {
    r=xWalkTree2(oNode,fnVisit,skip,data);if(r)return r;
    while(oNode)
    {
      var n=oNode;
      while(n=n.nextSibling){if(n!=skip){r=xWalkTree2(n,fnVisit,skip,data);if(r)return r;}}
      oNode=oNode.parentNode;
    }
  }
  return r;
}
// xWalkTree2, Copyright 2005-2007 Olivier Spinelli
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

// My humble contribution to the great cross-browser xLibrary file x_dom.js
//
// This function is compatible with Mike's but adds:
// - 'fnVisit' can return a non null object to stop the walk. This result will be returned to caller.
// See function xFindAfterByClassName below: it uses it.
// - 'fnVisit' accept one optional 'data' parameter
// - 'skip' is an optional element that will be ignored during traversal. It is often useful to skip
// the starting node: when skip == oNode, 'fnVisit' is not called but, of course, child are processed.
//
function xWalkTree2( oNode, fnVisit, skip, data )
{
  var r=null;
  if(oNode){if(oNode.nodeType==1&&oNode!=skip){r=fnVisit(oNode,data);if(r)return r;}
  for(var c=oNode.firstChild;c;c=c.nextSibling){if(c!=skip)r  =xWalkTree2(c,fnVisit,skip,data);if(r)return r;}}
  return r;
}
// xWalkTree3, Copyright 2005-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xWalkTree3(n,f,d,l,b)
{
  if (typeof l == 'undefined') l = 0;
  if (typeof b == 'undefined') b = 0;
  var v = f(n,l,b,d);
  if (!v) return 0;
  if (v == 1) {
    for (var c = n.firstChild; c; c = c.nextSibling) {
      if (c.nodeType == 1) {
        if (!l) ++b;
        if (!xWalkTree3(c,f,d,l+1,b)) return 0;
      }
    }
  }
  return 1;
}
// xWalkTree, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xWalkTree(n, f)
{
  f(n);
  for (var c = n.firstChild; c; c = c.nextSibling) {
    if (c.nodeType == 1) xWalkTree(c, f);
  }
}
// xWalkTreeRev, Copyright 2005-2007 Olivier Spinelli
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

//
// Same as xWalkTree2 except that traversal is reversed (last to first child).
//
function xWalkTreeRev( oNode, fnVisit, skip, data )
{
  var r=null;
  if(oNode){if(oNode.nodeType==1&&oNode!=skip){r=fnVisit(oNode,data);if(r)return r;}
  for(var c=oNode.lastChild;c;c=c.previousSibling){if(c!=skip)r=xWalkTreeRev(c,fnVisit,skip,data);if(r)return r;}}
  return r;
}
// xWalkUL, Copyright 2006-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xWalkUL(oUL,data,fn)
{
  var r, ul, li = xFirstChild(oUL);
  while (li) {
    ul = xFirstChild(li,'ul');
    r = fn(oUL,li,ul,data);
    if (ul) {
      if (!r || !xWalkUL(ul,data,fn)) {return 0;};
    }
    li = xNextSib(li);
  }
  return 1;
}
// xWidth, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xWidth(e,w)
{
  if(!(e=xGetElementById(e))) return 0;
  if (xNum(w)) {
    if (w<0) w = 0;
    else w=Math.round(w);
  }
  else w=-1;
  var css=xDef(e.style);
  if (e == document || e.tagName.toLowerCase() == 'html' || e.tagName.toLowerCase() == 'body') {
    w = xClientWidth();
  }
  else if(css && xDef(e.offsetWidth) && xStr(e.style.width)) {
    if(w>=0) {
      var pl=0,pr=0,bl=0,br=0;
      if (document.compatMode=='CSS1Compat') {
        var gcs = xGetComputedStyle;
        pl=gcs(e,'padding-left',1);
        if (pl !== null) {
          pr=gcs(e,'padding-right',1);
          bl=gcs(e,'border-left-width',1);
          br=gcs(e,'border-right-width',1);
        }
        // Should we try this as a last resort?
        // At this point getComputedStyle and currentStyle do not exist.
        else if(xDef(e.offsetWidth,e.style.width)){
          e.style.width=w+'px';
          pl=e.offsetWidth-w;
        }
      }
      w-=(pl+pr+bl+br);
      if(isNaN(w)||w<0) return;
      else e.style.width=w+'px';
    }
    w=e.offsetWidth;
  }
  else if(css && xDef(e.style.pixelWidth)) {
    if(w>=0) e.style.pixelWidth=w;
    w=e.style.pixelWidth;
  }
  return w;
}
// xWinClass, Copyright 2003-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

// xWinClass Object Prototype

function xWinClass(clsName, winName, w, h, x, y, loc, men, res, scr, sta, too)
{
  var thisObj = this;
  var e='',c=',',xf='left=',yf='top='; this.n = name;
  if (document.layers) {xf='screenX='; yf='screenY=';}
  this.f = (w?'width='+w+c:e)+(h?'height='+h+c:e)+(x>=0?xf+x+c:e)+
    (y>=0?yf+y+c:e)+'location='+loc+',menubar='+men+',resizable='+res+
    ',scrollbars='+scr+',status='+sta+',toolbar='+too;
  this.opened = function() {return this.w && !this.w.closed;};
  this.close = function() {if(this.opened()) this.w.close();};
  this.focus = function() {if(this.opened()) this.w.focus();};
  this.load = function(sUrl) {
    if (this.opened()) this.w.location.href = sUrl;
    else this.w = window.open(sUrl,this.n,this.f);
    this.focus();
    return false;
  };
  // Closures
  // this == <A> element reference, thisObj == xWinClass object reference
  function onClick() {return thisObj.load(this.href);}
  // '*' works with any element, not just A
  xGetElementsByClassName(clsName, document, '*', bindOnClick);
  function bindOnClick(e) {e.onclick = onClick;}
}
// xWindow, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xWindow(name, w, h, x, y, loc, men, res, scr, sta, too)
{
  var e='',c=',',xf='left=',yf='top='; this.n = name;
  if (document.layers) {xf='screenX='; yf='screenY=';}
  this.f = (w?'width='+w+c:e)+(h?'height='+h+c:e)+(x>=0?xf+x+c:e)+
    (y>=0?yf+y+c:e)+'location='+loc+',menubar='+men+',resizable='+res+
    ',scrollbars='+scr+',status='+sta+',toolbar='+too;
  this.opened = function() {return this.w && !this.w.closed;};
  this.close = function() {if(this.opened()) this.w.close();};
  this.focus = function() {if(this.opened()) this.w.focus();};
  this.load = function(sUrl) {
    if (this.opened()) this.w.location.href = sUrl;
    else this.w = window.open(sUrl,this.n,this.f);
    this.focus();
    return false;
  };
}

// Previous implementation:
// function xWindow(name, w, h, x, y, loc, men, res, scr, sta, too)
// {
//   var f = '';
//   if (w && h) {
//     if (document.layers) f = 'screenX=' + x + ',screenY=' + y;
//     else f = 'left=' + x + ',top=' + y;
//     f += ',width=' + w + ',height=' + h + ',';
//   }
//   f += ('location='+loc+',menubar='+men+',resizable='+res
//     +',scrollbars='+scr+',status='+sta+',toolbar='+too);
//   this.features = f;
//   this.name = name;
//   this.load = function(sUrl) {
//     if (this.wnd && !this.wnd.closed) this.wnd.location.href = sUrl;
//     else this.wnd = window.open(sUrl, this.name, this.features);
//     this.wnd.focus();
//     return false;
//   }
// }
// xWinOpen, Copyright 2003-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

// A simple alternative to xWindow.

var xChildWindow = null;
function xWinOpen(sUrl)
{
  var features = "left=0,top=0,width=600,height=500,location=0,menubar=0," +
    "resizable=1,scrollbars=1,status=0,toolbar=0";
  if (xChildWindow && !xChildWindow.closed) {xChildWindow.location.href  = sUrl;}
  else {xChildWindow = window.open(sUrl, "myWinName", features);}
  xChildWindow.focus();
  return false;
}
// xWinScrollTo, Copyright 2003-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

var xWinScrollWin = null;
function xWinScrollTo(win,x,y,uTime) {
  var e = win;
  if (!e.timeout) e.timeout = 25;
  var st = xScrollTop(e, 1);
  var sl = xScrollLeft(e, 1);
  e.xTarget = x; e.yTarget = y; e.slideTime = uTime; e.stop = false;
  e.yA = e.yTarget - st;
  e.xA = e.xTarget - sl; // A = distance
  if (e.slideLinear) e.B = 1/e.slideTime;
  else e.B = Math.PI / (2 * e.slideTime); // B = period
  e.yD = st;
  e.xD = sl; // D = initial position
  var d = new Date(); e.C = d.getTime();
  if (!e.moving) {
    xWinScrollWin = e;
    _xWinScrollTo();
  }
}
function _xWinScrollTo() {
  var e = xWinScrollWin || window;
  var now, s, t, newY, newX;
  now = new Date();
  t = now.getTime() - e.C;
  if (e.stop) { e.moving = false; }
  else if (t < e.slideTime) {
    setTimeout("_xWinScrollTo()", e.timeout);

    s = e.B * t;
    if (!e.slideLinear) s = Math.sin(s);
//    if (e.slideLinear) s = e.B * t;
//    else s = Math.sin(e.B * t);

    newX = Math.round(e.xA * s + e.xD);
    newY = Math.round(e.yA * s + e.yD);
    e.scrollTo(newX, newY);
    e.moving = true;
  }  
  else {
    e.scrollTo(e.xTarget, e.yTarget);
    xWinScrollWin = null;
    e.moving = false;
    if (e.onslideend) e.onslideend();
  }  
}
// xZIndex, Copyright 2001-2007 Michael Foster (Cross-Browser.com)
// Part of X, a Cross-Browser Javascript Library, Distributed under the terms of the GNU LGPL

function xZIndex(e,uZ)
{
  if(!(e=xGetElementById(e))) return 0;
  if(e.style && xDef(e.style.zIndex)) {
    if(xNum(uZ)) e.style.zIndex=uZ;
    uZ=parseInt(e.style.zIndex);
  }
  return uZ;
}
