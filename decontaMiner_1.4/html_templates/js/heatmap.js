var maxrowlen=0;   ///max. no of character in row lebel
for(i=0;i<rowLabel.length;i++)
  {
    if(maxrowlen<rowLabel[i].length){ maxrowlen=rowLabel[i].length; }
  }
var maxcollen=0;   ///max. no of character in col lebel
for(i=0;i<colLabel.length;i++)
  { 
    if(maxcollen<colLabel[i].length){ maxcollen=colLabel[i].length; }
  }


var colors = ['#618685','#6B9493','#7A9F9D','#89A9A8','#97B4B3','#B5C9C9','#C4D4D4','#D3DFDE','#E1EAE9','#F0F4F4','#FFFFFF','#FFFAE6','#FFF5CC','#FFF0B3','#FFEB99','#FFE680','#FFE066','#FFDB4D','#FFD11A','#FFCC00','#E6B800'];
var colorBuckets = colors.length;

var cellSize= 30,
  legendboxsize=cellSize/2,
  col_number=colLabel.length,
  row_number=rowLabel.length,
  legendElementWidth=0,
   width=0;

//this is for bottom label length
 if (col_number < 21)
  {legendElementWidth = cellSize; 
   width = (cellSize*21);
  }
 else 
  { 
    width = (cellSize*col_number); //+margin.left +margin.right, 
    legendElementWidth = width/(colorBuckets);
  } 

  var height = cellSize*row_number , // - margin.top - margin.bottom,
  hcrow = d3.range(1,row_number),  
  hccol = d3.range(1,col_number);
  var margin = {top: (maxcollen*2.5)+300, right: 100, bottom: (rowLabel.length*2)+50, left: (maxrowlen*2.5)+300};  //300px is fixed margin for top and left after that it will increase as per the length of label


var maxvalue=d3.max(data, function(d) {return d.value; }); //alert(maxvalue);
var minvalue=d3.min(data, function(d) {return d.value; }); 
var average=(maxvalue+minvalue)/2; //alert(average);


var colorScale = d3.scale.quantile()
  .domain([0,average,maxvalue])    ///if we don't have values in negative (0, avg, max)
  .range(colors)

  var svg = d3.select("#chart").append("svg").attr("id","svg3")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  var rowSortOrder=false;
  var colSortOrder=false;
  var rowLabels = svg.append("g")
      .selectAll(".rowLabelg")
      .data(rowLabel)
      .enter()
      .append("text")
      .text(function (d) { return modify(d,17,30,50); })     //will show label till first 15 and then ...and last
      .attr("x", -((maxrowlen*0.25)+80))                     //80 px is fixed gap between map and label, later as per clabel length
      .attr("y", function (d, i) { return hcrow.indexOf(i) * cellSize; })
      .style("text-anchor", "end")
      .attr("transform", "translate(-6," + cellSize / 1.5 + ")")
      .attr("class", function (d,i) { return "rowLabel mono r"+i;} ) 
      .on("mouseover", function(d) {d3.select(this).classed("text-hover",true);})
      .on("mouseout" , function(d) {d3.select(this).classed("text-hover",false);})
      //.on("click", function(d,i) {rowSortOrder=!rowSortOrder; sortbylabel("r",i,rowSortOrder);d3.select("#order").property("selectedIndex", 4).node().focus();;})
      ;


  var colLabels = svg.append("g")
      .selectAll(".colLabelg")
      .data(colLabel)
      .enter()
      .append("text")
      .text(function (d) { return modify(d,17,30,50);; })   //will show label till first 15 and then ...and last
      .attr("x", (maxcollen*0.25)+30)                                        //increase the space for x axis and accordingly chage the margin from left
      .attr("y", function (d, i) { return hccol.indexOf(i) * cellSize; })
      .style("text-anchor", "left")
      .attr("transform", "translate("+cellSize/2 + ",-36) rotate (-90)")
      .attr("class",  function (d,i) { return "colLabel mono c"+i;} )
      .on("mouseover", function(d) {d3.select(this).classed("text-hover",true);})
      .on("mouseout" , function(d) {d3.select(this).classed("text-hover",false);})
      //.on("click", function(d,i) {colSortOrder=!colSortOrder;  sortbylabel("c",i,colSortOrder);d3.select("#order").property("selectedIndex", 4).node().focus();;})
      ;

  function dblclick(a){
    window.location.assign("http://en.wikipedia.org/wiki/", '_blank');
 }

  var heatMap = svg.append("g").attr("class","g3")
        .selectAll(".cellg")
        .data(data,function(d){return d.row+":"+d.col;})
        .enter()
        .append("rect")
        .attr("x", function(d) { return hccol.indexOf(d.col-1) * cellSize; })    //here index change
        .attr("y", function(d) { return hcrow.indexOf(d.row-1) * cellSize; })  //here index change
        .attr("class", function(d){return "cell cell-border cr"+(d.row)+" cc"+(d.col);})
        .attr("width", cellSize)
        .attr("height", cellSize)
        .style("fill", function(d) { return colorScale(d.value); })

        .on("mouseover", function(d){
               //highlight text
               d3.select(this).classed("cell-hover",true);
               d3.selectAll(".rowLabel").classed("text-highlight",function(r,ri){ return ri==(d.row-1);});
               d3.selectAll(".colLabel").classed("text-highlight",function(c,ci){ return ci==(d.col-1);});
        
               //Update the tooltip position and value
               d3.select("#tooltip")
                 .style("left", (d3.event.pageX+10) + "px")
                 .style("top", (d3.event.pageY-10) + "px")
                 .select("#value")
                 .text("Organism name:"+rowLabel[d.row-1]+", sample id: "+colLabel[d.col-1]+", contamination: "+d.value + "%")                 //.text("lables:"+rowLabel[d.row-1]+","+colLabel[d.col-1]+"\ndata:"+d.value+"\nrow-col-idx:"+d.col+","+d.row+"\ncell-xy "+this.x.baseVal.value+", "+this.y.baseVal.value) 
               
               //Show the tooltip
               d3.select("#tooltip").classed("hidden", false);
        })
        .on("mouseout", function(){
               d3.select(this).classed("cell-hover",false);
               d3.selectAll(".rowLabel").classed("text-highlight",false);
               d3.selectAll(".colLabel").classed("text-highlight",false);
               d3.select("#tooltip").classed("hidden", true);
        })
        ;

//////////////////////////defined color range/////////////////
   
function xah_range (min, max, delta) {
   var arr = [];
    var myStepCount;
    if ( arguments.length === 1 ) {
        for (var ii = 0; ii < min; ii++) {
            arr[ii] = ii+1;
        };
    } else {
        if ( arguments.length === 2 ) {
            myStepCount = (max - min);
            for (var ii = 0; ii <= myStepCount; ii++ ) {
                arr.push(ii + min);
            };
        } else {
            myStepCount = Math.floor((max - min)/delta);
            for (var ii = 0; ii <= myStepCount; ii++ ) {
                arr.push(ii * delta + min);
            };
        }
    }
 return arr;
}
var interval=100/(colorBuckets-1);  //var interval=maxvalue/(colorBuckets-1);  
  var numbers=xah_range(0,100,interval);//to show on percentage levwl i put it 0 to 100. //var numbers=xah_range(minvalue,maxvalue,interval);
var x = 0;
while(x < numbers.length){ 
    numbers[x] =  Math.round(numbers[x]); 
    x++
}   

 ///////////////////////////////////////////////////////////////////// 

  var legend = svg.selectAll(".legend")
      .data(numbers)
      .enter().append("g")
      .attr("class", "legend");
 
  legend.append("rect")
    .attr("x", function(d, i) { return (legendElementWidth*i)-cellSize; })   //position of legend boxes in x axis 
    .attr("y", height+(legendboxsize))                                 //position of legend boxes in x axis, two cellsize down after graph
    .attr("width", legendElementWidth)
    .attr("height", legendboxsize)
    .style("fill", function(d, i) { return colors[i]; });
 
  legend.append("text")
    .attr("class", "mono")
    .text(function(d) { return d; })
    .attr("width", legendElementWidth)                              
    .attr("x", function(d, i) { return (legendElementWidth*i)-cellSize; }) //position of legend text in x axis -cellSize;
    .attr("y", height + (legendboxsize*3));                           //position of legend text in x axis, fourd cellsize down after graph

       // Change ordering of cells

 
      

  function sortbylabel(rORc,i,sortOrder){
       var t = svg.transition().duration(3000);
       var log2r=[];
       var sorted; // sorted is zero-based index
       d3.selectAll(".c"+rORc+i) 
         .filter(function(ce){
            log2r.push(ce.value);
          })
       ;
       if(rORc=="r"){ // sort log2ratio of a gene
         sorted=d3.range(col_number).sort(function(a,b){ if(sortOrder){ return log2r[b]-log2r[a];}else{ return log2r[a]-log2r[b];}});
         t.selectAll(".cell")
           .attr("x", function(d) { return (sorted.indexOf(d.col-1) * cellSize)-cellSize; }) //
           ;
         t.selectAll(".colLabel")
          .attr("y", function (d, i) { return (sorted.indexOf(i) * cellSize)-cellSize; })  //-cellSize
         ;
       }else{ // sort log2ratio of a contrast
         sorted=d3.range(row_number).sort(function(a,b){if(sortOrder){ return log2r[b]-log2r[a];}else{ return log2r[a]-log2r[b];}});
         t.selectAll(".cell")
           .attr("y", function(d) { return (sorted.indexOf(d.row-1) * cellSize)-cellSize; }) //
           ;
         t.selectAll(".rowLabel")
          .attr("y", function (d, i) { return (sorted.indexOf(i) * cellSize)-cellSize; }) //-cellSize
         ;
       }
  }

  d3.select("#order").on("change",function(){
 order(this.value);
  });
  
  function order(value){
   if (value=="probecontrast"){
    var t = svg.transition().duration(3000);
    t.selectAll(".cell")
      .attr("x", function(d) { return (d.col - 1) * cellSize; })
      .attr("y", function(d) { return (d.row - 1) * cellSize; })
      ;

    t.selectAll(".rowLabel")
      .attr("y", function (d, i) { return i * cellSize; })
      ;

    t.selectAll(".colLabel")
      .attr("y", function (d, i) { return i * cellSize; })
      ;

   }else if (value=="probe"){
    var t = svg.transition().duration(3000);
    t.selectAll(".cell")
      .attr("y", function(d) { return (d.row - 1) * cellSize; })
      ;

    t.selectAll(".rowLabel")
      .attr("y", function (d, i) { return i * cellSize; })
      ;
   }else if (value=="contrast"){
    var t = svg.transition().duration(3000);
    t.selectAll(".cell")
      .attr("x", function(d) { return (d.col - 1) * cellSize; })
      ;
    t.selectAll(".colLabel")
      .attr("y", function (d, i) { return i * cellSize; })
      ;
   }
  }
  // //////////////////////////////////////////////////////////////////////////
  var sa=d3.select(".g3")
    
      .on("mousedown", function() {
          if( !d3.event.altKey) {
             d3.selectAll(".cell-selected").classed("cell-selected",false);
             d3.selectAll(".rowLabel").classed("text-selected",false);
             d3.selectAll(".colLabel").classed("text-selected",false);
          }
         var p = d3.mouse(this);
         sa.append("rect")
         .attr({
             rx      : 0,
             ry      : 0,
             class   : "selection",
             x       : p[0],
             y       : p[1],
             width   : 1,
             height  : 1
         })
      })
      .on("mousemove", function() {
         var s = sa.select("rect.selection");
      
         if(!s.empty()) {
             var p = d3.mouse(this),
                 d = {
                     x       : parseInt(s.attr("x"), 10),
                     y       : parseInt(s.attr("y"), 10),
                     width   : parseInt(s.attr("width"), 10),
                     height  : parseInt(s.attr("height"), 10)
                 },
                 move = {
                     x : p[0] - d.x,
                     y : p[1] - d.y
                 }
             ;
      
             if(move.x < 1 || (move.x*2<d.width)) {
                 d.x = p[0];
                 d.width -= move.x;
             } else {
                 d.width = move.x;       
             }
      
             if(move.y < 1 || (move.y*2<d.height)) {
                 d.y = p[1];
                 d.height -= move.y;
             } else {
                 d.height = move.y;       
             }
             s.attr(d);
      
                 // deselect all temporary selected state objects
             d3.selectAll('.cell-selection.cell-selected').classed("cell-selected", false);
             d3.selectAll(".text-selection.text-selected").classed("text-selected",false);

             d3.selectAll('.cell').filter(function(cell_d, i) {
                 if(
                     !d3.select(this).classed("cell-selected") && 
                         // inner circle inside selection frame
                     (this.x.baseVal.value)+cellSize >= d.x && (this.x.baseVal.value)<=d.x+d.width && 
                     (this.y.baseVal.value)+cellSize >= d.y && (this.y.baseVal.value)<=d.y+d.height
                 ) {
      
                     d3.select(this)
                     .classed("cell-selection", true)
                     .classed("cell-selected", true);

                     d3.select(".r"+(cell_d.row-1))
                     .classed("text-selection",true)
                     .classed("text-selected",true);

                     d3.select(".c"+(cell_d.col-1))
                     .classed("text-selection",true)
                     .classed("text-selected",true);
                 }
             });
         }
      })
      .on("mouseup", function() {
            // remove selection frame
         sa.selectAll("rect.selection").remove();
      
             // remove temporary selection marker class
         d3.selectAll('.cell-selection').classed("cell-selection", false);
         d3.selectAll(".text-selection").classed("text-selection",false);
      })
      .on("mouseout", function() {
         if(d3.event.relatedTarget.tagName=='html') {
                 // remove selection frame
             sa.selectAll("rect.selection").remove();
                 // remove temporary selection marker class
             d3.selectAll('.cell-selection').classed("cell-selection", false);
             d3.selectAll(".rowLabel").classed("text-selected",false);
             d3.selectAll(".colLabel").classed("text-selected",false);
         }
      })
      ;

      ///////////////downlaod image//////////////////////////////////

d3.select("#saveheatmap2").on("click", function(){  
   var html1 = d3.select("#svg3") 
        .attr("version", 1.1)
        .attr("xmlns", "http://www.w3.org/2000/svg")
        .node( ).parentNode.innerHTML;   //node().parentNode.innerHTML;
        //console.log(html);
       
  var imgsrc1 = 'data:image/svg+xml;base64,'+ btoa(html1);
  var image1 = new Image;
  image1.src = imgsrc1;
  
  image1.onload = function() {
  var canvas = document.createElement('canvas');
  canvas.width = image1.width;
  canvas.height = image1.height;
  var context = canvas.getContext('2d');
  context.fillStyle = "#FFFFFF";
  context.fillRect(0,0,image1.width,image1.height);
  context.drawImage(image1, 0, 0);
 
  var a1 = document.createElement('a');
  a1.download = "heatmap.png";
  a1.href = canvas.toDataURL('image/png');
  document.body.appendChild(a1);
  a1.click();    //window.open(a1.click(), "_blank");  incase mouse stuck after clicking on downlaod
}
}); 
