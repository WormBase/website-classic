var xVersion='3.15.4',xNN4,xOp7,xOp5or6,xIE4Up,xIE4,xIE5,xIE5Up,xIE6,xUA=navigator.userAgent.toLowerCase(),xUAVersion=parseFloat(navigator.appVersion);
var xUAgent=xUA.substring(0,xUA.indexOf('/'));
if (window.opera){
  xOp7=(xUA.indexOf('opera 7')!=-1 || xUA.indexOf('opera/7')!=-1);
  if (!xOp7) xOp5or6=(xUA.indexOf('opera 5')!=-1 || xUA.indexOf('opera/5')!=-1 || xUA.indexOf('opera 6')!=-1 || xUA.indexOf('opera/6')!=-1);
}
else if (document.all && xUA.indexOf('msie')!=-1) {
  xIE4Up=xUAVersion >=4;
  xIE5Up=xUAVersion >=5;
  xIE4=xUA.indexOf('msie 4')!=-1;
  xIE5=xUA.indexOf('msie 5')!=-1;
  xIE6=xUA.indexOf('msie 6')!=-1;
}
else if (document.layers) {xNN4=true;}
xMoz=xUA.indexOf('gecko')!=-1;
xMac=xUA.indexOf('mac')!=-1;
xSafari=xUA.indexOf('safari')!=-1;
