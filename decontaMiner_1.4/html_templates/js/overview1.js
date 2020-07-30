//checking for maximum number of species in each samples////////////////////////////
var maxspecies=0;
for(var i = 0; i <data.length; i++) 
{
var arrspecies = data[i].nsamples; 
var numberofsamples = Object.keys(arrspecies).length;  //alert(numberofsamples);
if(maxspecies < numberofsamples){
maxspecies=numberofsamples;
}
}

var ticks = d3.range(0,maxspecies);   
var margin = {top: 220, right: 100, bottom: 10, left: 250};
var width = xaxis.length*40, 
    height = 40 * data.length;  //alert(width);
    
/////////color and its shades/////////////////
///1:blue,  2: green, 3:light orange, 4: red, 5:brown, 6:violet
var Set3 = [
["#004d66","#006080","#007399","#0086b3","#0099cc","#00ace6","#00bfff","#1ac6ff","#33ccff","#4dd2ff","#66d9ff"], 
["#2d862d","#339933","#39ac39","#40bf40","#53c653","#66cc66","#79d279","#8cd98c","#9fdf9f","#b3e6b3","#c6ecc6"], 
["#995c00","#b36b00","#cc7a00","#e68a00","#ff9900","#ffa31a","#ffad33","#ffb84d","#ffc266","#ffcc80","#ffd699"],
["#cc0000","#e60000","#ff0000","#ff1a1a","#ff3333","#ff4d4d","#ff5050","#ff6666","#ff8080","#ff9999","#ffb3b3"], 
["#6b302e","#7d3836","#843c39","#8f403d","#a14845","#b3504d","#ba615e","#c27370","#c98482","#d19694","#d9a7a6"], 
["#4d0099","#5900b3","#6600cc","#7300e6","#8000ff","#8c1aff","#9933ff","#a64dff","#b366ff","#bf80ff","#cc99ff"], 
 ];

