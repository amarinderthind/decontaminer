//Tooltip description
var tooltip = d3.select("body")
    .append("div")
    .attr("id", "tooltip")
    .style("position", "absolute")
    .style("z-index", "10")
    .style("opacity", 0);

var tooltip1 = d3.select("body")
  .append("div")  // declare the tooltip div 
  .attr("class", "tooltip1")              // apply the 'tooltip' class
  .style("opacity", 0);

function samplearcin(d) {
       d3.select(this).attr("stroke","black")
       
          tooltip.html('Click here, to view the detail of :'+xaxis[d] );  //format_description(d)
          return tooltip.transition()
            .duration(50)
            .style("opacity", 0.9);
        }

function samplearcout(){
  d3.select(this).attr("stroke","")
  return tooltip.style("opacity", 0);
}

function samplearcmove (d) {
          return tooltip
            .style("top", (d3.event.pageY-10)+"px")
            .style("left", (d3.event.pageX+10)+"px");
} 


//////////////////////////
var x = d3.scale.linear()
    .range([0, width]);

var svg2 = d3.select("#ballgraph").append("svg").attr("id","svg2")
    .attr("class","scroll-svg")
    .attr("width", width + margin.left + margin.right+50)
    .attr("height", height + margin.top + margin.bottom+50)
    .style("margin-left", margin.left/3 + "px")
    .style("margin-top", margin.top/3 + "px")
    .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

 
    x.domain([0, data[0].nsamples.length-1]);
    var xScale = d3.scale.linear()
        .domain([0, data[0].nsamples.length-1])
        .range([0, width]);

var xAxis = d3.svg.axis()
        .scale(x)
        .orient("top")
        .tickValues(ticks)
        .tickFormat(function(d,i){ return xaxis[i] });  //x label defined with string and modified length
                
    svg2.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + 0 + ")")
        .call(xAxis)
        .selectAll("text")  
            .style("text-anchor", "start")
            .attr("dx", "-.9em")
            .attr("dy", ".15em")
            .attr("y",2)
            .attr("x",+20)
            .attr("transform", function(d) {
                return "rotate(-88)"                 
                })
            .on("mouseover", samplearcin)
            .on("mousemove", samplearcmove)
            .on("mouseout", samplearcout)
            .on("click", function(d,i){
          
               var idsample= xaxis[i];
                window.location=sample_dir+idsample+'_'+grouptype+'_CT_'+ MC_thresh+'.html';
              })  ;
/////////to cluster the species//////////////
var original = data[0];
var ori = original.name;    
var orig=ori.split(" ");
var color=0;
var color2=0;
//alert(data.length);
/////////////////////////////////////////////

var maxvaluefromdata=0;
var org_names=[];
for (var j = 0; j < data.length; j++) { 
var linevmaxvalue=d3.max(data[j]['nsamples'], function(d) { return d[1]; });
org_names.push(data[j]['name']);

if(maxvaluefromdata<linevmaxvalue){ maxvaluefromdata=linevmaxvalue}
}
//alert(maxvaluefromdata);

for (var j = 0; j < data.length; j++) {

        var g = svg2.append("g").attr("class","journal");

        var text = g.selectAll("text")
            .data(data[j]['nsamples'])
            .enter()
            .append("text")
            ;

        var rScale = d3.scale.linear()
            .domain([0,maxvaluefromdata]) ///define range over min and max. value of whole data
            .range([2, 25]);


      var circles = g.selectAll("circle")
                  .data(data[j]['nsamples'])
                  .enter()
                  .append("circle");


        /////////////to cluster the species////////////////////////
        var arrspecies = data[j]; 
        var numberofsamples = arrspecies.name;  //alert(numberofsamples);
        var currentline=numberofsamples.split(" ");       
        if (currentline[0]!=orig) {
           if (j==0){
              color=0;
           } else {
            color++; //alert(color);
           }
           orig = currentline[0];
           
         color2=0;
         if (color>5) { color=0;}   
        }
        //////////////////////////////////////////////////


        circles
            .attr("cx", function(d, i) { return xScale(d[0]); })
            .attr("cy", j*40+20)
            .attr("r", function(d) { 
                                     if(d[1]==0){ return 0; }else{return rScale(d[1]);} // to maintain the scale from 2. to 25 for redius i am sending 0 for 0 value for rest it will start from 2
                                     })
            .style("fill", function(d) {  return Set3[color][color2]; }) 
            .on("mouseover", function(d){
               //Update the tooltip position and value
               d3.select("#tooltip")
                 .style("left", (d3.event.pageX+10) + "px")
                 .style("top", (d3.event.pageY-10) + "px")
                 .select("#value")
                 .text('Organism :'+ org_names[d[2]] + '; Sample name : '+xaxis[d[0]] + '; Match Count (MC):'+d[1])
                 d3.select("#tooltip").classed("hidden", false);
              })
            .on("mouseout", function(){  d3.select("#tooltip").classed("hidden", true); });
        //            .on("mouseover", mouseOverArc)
        //           .on("mousemove", mouseMoveArc)
        //          .on("mouseout", mouseOutArc);

        text
            .attr("y", j*40+25)
            .attr("x",function(d, i) { return xScale(d[0])-5; })
            .attr("class","value")
            .text(function(d){ return d[1]; })
            .style("fill", function(d) { return Set3[color][color2]; })       //defined ball color here
            .style("display","none")
            ; 

        //g.append("a")
        //.attr("xlink:href", "http://en.wikipedia.org/wiki/"+data[j]['name'])
        g.append("text")
            .attr("y", j*40+25)
            .attr("x",-200)
            .attr("class","label")
            .text(modify(data[j]['labname'],30,18,"50"))                         //modify(data[j]['labname'],3,15,"25")
            .style("fill", function(d) { return Set3[color][color2]; }) 
            ;   
        //////repeat colors//////////  
            color2++; 
            if (color2>10) { color2=0;}   
        /////////////////////////////////   
}; // endfor

///////////////downlaod image//////////////////////////////////
var scaletimes=1;
d3.select("#saveballgraph").on("click", function(){  
   var html1 = d3.select("#svg2") 
        .attr("version", 1.1)
        .attr("xmlns", "http://www.w3.org/2000/svg")
        .node( ).parentNode.innerHTML;   
       
  var imgsrc1 = 'data:image/svg+xml;base64,'+ btoa(html1);
    var image1 = new Image;
    image1.src = imgsrc1;
    
  image1.onload = function() {
  var canvas = document.createElement('canvas');
  canvas.width = image1.width*scaletimes;
  canvas.height = image1.height*scaletimes;
  var context = canvas.getContext('2d');
  context.fillStyle = "#FFFFFF";
  context.fillRect(0,0,image1.width*scaletimes,image1.height*scaletimes);
  context.drawImage(image1, 0, 0,image1.width*scaletimes,image1.height*scaletimes);
 
  var a1 = document.createElement('a');
  a1.download = "graphball.png";
  a1.href = canvas.toDataURL('image/png');
  document.body.appendChild(a1);

  //console.log(canvas);
  //console.log(a1);
  a1.click();     //window.open(a1.click(), "_blank");  incase mouse stuck after clicking on downlaod
  
}
});

