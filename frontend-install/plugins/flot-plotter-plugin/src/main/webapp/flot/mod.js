// Fuego Plotting Script

// Copyright (c) 2014 Cogent Embedded, Inc.

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

jQuery.noConflict();
jQuery(document).ready(function () {

    var localurl = jQuery(location).attr('href').split("/");
    var pathname = jQuery(location).attr('pathname').split("/");

    var prefix = pathname[1];
    var i = 2;
    while (pathname[i] != "view" && pathname[i] != "job") {
    	prefix = prefix + '/' + pathname[i];
    	i++;
    }

    var jenurl = 'http://'+'/'+location['host'] + '/' + prefix +'/userContent/fuego.logs/';

    // testname is currently: (<board>.<testplan>.Benchmark.<testsuite>)
    var testname = localurl[localurl.length - 2],
      testsuite = testname.split(".")[3],
      metrics = [],
      tests = [],
      plots = [],
      fws = [],
      devices = [],
      glob_suffix = '**',
      fw_ver_len = 12,
      fw_ver_prefix_len = fw_ver_len - glob_suffix.length;

  var options = {
    lines: { show: true , lineWidth:1.2 },
    points: { show: true },
    xaxis: {},
    yaxis: {},
    grid: { hoverable: true, clickable: true, backgroundColor: "#f5f5f5", borderWidth: 0.5 },
    pan: { interactive: true },
    zoom: { interactive: true },
    legend: { position: 'nw', noColumns:2, container: null },
    colors: ["#008f00", "#73fa79", "#009193", "#73fcd6", "#ff9300", "#ffd479", "#942193", "#d783ff", "#424242", "#a9a9a9", "#011993", "#76d6ff", "#929000", "#fffc79", "#941100", "#ff7e79"]
  };
  var options_f = {
    lines: { show: true, lineWidth:1.0 },
    points: { show: false },
    grid: { backgroundColor: "#f0f0f0", borderWidth: 0.5 },
    legend: { show: false },
    selection: { mode: "x", color: "blue" },
    // colors: ["#0000ff", "#008000", "#00bfbf", "#148f8f", "#bf00bf", "#bfbf00", "#000", "#3cff00"]
    colors: ["#008f00", "#73fa79", "#009193", "#73fcd6", "#ff9300", "#ffd479", "#942193", "#d783ff", "#424242", "#a9a9a9", "#011993", "#76d6ff", "#929000", "#fffc79", "#941100", "#ff7e79"]
  };

function getSuitesInfo(series) {
    if (testsuite in series) {
	metrics = series[testsuite];
	for (var i=0;i<metrics.length;i++) {
	    jQuery('.plots').append('<div class="container"><div class="area_header">'+testsuite+' / '+metrics[i]+'</div>'+
				    '<div class="cont2"><div style="width:800px;height:200px;float:right" id="ph'+i+'"></div><p></p><div style="width:800px;height:70px;float:right" id="phf'+i+'"></div></div>'+
				    '<div class="cont3">Legend:<div id="phl'+i+'"></div><br/>'+
				    '<div class="devices"><input type="checkbox" name="all_dev" checked="checked" id="all_dev_'+i+'"><label for="all_dev">All devices:</label><br/><div id="pht'+i+'"></div></div>'+
				    '<div class="firmware"><input type="checkbox" name="all_fw" checked="checked" id="all_fw_'+i+'"><label for="all_fw">All firmware:</label><br/><div id="phfw'+i+'"></div>'+
				    '</div></div>');
	}
    }
    else {
	jQuery('.plots').append('<div class="container"><div class="area_header">'+testsuite+':'+ 'No data (check metrics.json file)' +'</div>'
				+'</div></div>');
    }
}

function getBuildsInfo(series) {
  devices = series;
  devices.forEach(function(dev){
    dev['info'][1].forEach(function(fw){
     if (fws.indexOf(fw) == -1) {
       fws.push(fw);}});});
  fws.sort();
  fws.reverse();
}

jQuery.ajax({ url: jenurl+'/Benchmark.'+testsuite+'/metrics.json', method: 'GET', dataType: 'json', async: false, success: getSuitesInfo});
jQuery.ajax({ url: jenurl+'/Benchmark.'+testsuite+'/Benchmark.'+testsuite+'.info.json', method: 'GET', dataType: 'json', async: false, success: getBuildsInfo});

for (var i=0;i<metrics.length;i++) {
  var tmp_ph = "#ph"+i,
    placeholder = jQuery("#ph"+i),
    placeholder_f = jQuery("#phf"+i),
    legend = jQuery("#phl"+i),
    target_list = jQuery("#pht"+i),
    plot, plot_f,
    previousPoint = null;

  jQuery.ajax({url:jenurl+'/Benchmark.'+testsuite+'/Benchmark.'+testsuite+'.'+metrics[i]+'.json',method:'GET',dataType:'json',async:false,success:onDataReceived});
  jQuery(placeholder_f).bind("plotselected", hand_o);
  jQuery("#pht"+i+" input").click(drawChoices);
  jQuery("#all_dev_"+i).click(drawChoices);
  jQuery("#phfw"+i+" input").click(drawChoices);
  jQuery("#all_fw_"+i).click(drawChoices);
  jQuery(placeholder).bind("plothover", MoreInfo_PopUp);
}

function MoreInfo_PopUp (event, pos, item) {
  var fw, sdk, name;
  if (item) {
    jQuery("#tooltip").remove();
    if (previousPoint != item.dataIndex) {
      previousPoint = item.dataIndex;
      var x = item.datapoint[0].toFixed(2),
          y = item.datapoint[1].toFixed(2),
          id = -1,
          o = 0;

      while (id < 0) {
      	id = devices[o]['info'][0].indexOf(parseFloat(x).toString());
        if (id >= 0) {
          fw = devices[o]['info'][1][id];
          sdk = devices[o]['info'][2][id];
          name = devices[o].device;
        }
        o++;
      }

      if (fw){
        previousPoint = null;
        showTooltip(item.pageX,item.pageY,"<b>"+item.series.label+"</b>"+
          "<br/>Build: "+parseFloat(x).toFixed()+
          "<br/>Device: "+name+
          "<br/>Value: "+y+
          "<br/>SDK: "+sdk+
          "<br/>FW: "+fw);
      }
    }
  }
  else {
    jQuery("#tooltip").remove();
    previousPoint = null;
  }
}

function hand_o (event,ranges) {
  var n = parseInt(this.id.substring(this.id.length-1));
  plots[n][0]=jQuery.plot(jQuery("#ph"+n),plots[n][2],jQuery.extend(true,{},options,{
    xaxis:{min:ranges.xaxis.from, max:ranges.xaxis.to},
    yaxis: {min:ranges.yaxis.from,max:ranges.yaxis.to}
  }));
}

function drawChoices() {
  var res = [], checked_fw = [], checked_dev = [],
      all_devs_checked = false, all_fw_checked = false,
      k = parseInt(this.id.slice(-1)); // XXX this assumes the maximum of 10 graphs!

  // Handle group check-boxes, and set all_*_checked falgs
  if (jQuery(this).attr("name") == "all_dev") {
    all_devs_checked = jQuery(this).attr("checked");
    jQuery("#pht"+k+" input").attr("checked", all_devs_checked);
  } else if (jQuery(this).attr("name") == "all_fw") {
    all_fw_checked = jQuery(this).attr("checked");
    jQuery("#phfw"+k+" input").attr("checked", all_fw_checked);
  }

  if (!all_devs_checked) {
    all_devs_checked = (jQuery("#pht"+k+" input:checked").length == jQuery("#pht"+k+" input").length);
    jQuery("#all_dev_"+k).attr("checked", all_devs_checked);
  }

  if (!all_fw_checked) {
    all_fw_checked = (jQuery("#phfw"+k+" input:checked").length == jQuery("#phfw"+k+" input").length);
    jQuery("#all_fw_"+k).attr("checked", all_fw_checked);
  }

  jQuery("#pht"+k+" input:checked").each(function(){
    var devname = jQuery(this).attr("name");
    devices.forEach(function(dev){
     	if (dev.device == devname) {
        checked_dev.push(jQuery.extend(true, {}, dev))}});
  });

  checked_dev.forEach(function(dev){
    var new_bids = [];
    jQuery("#phfw"+k+" input:checked").each(function(){
      var fwname = jQuery(this).attr("name");
      for (var f=0; f<dev.info[1].length; f++) {
	var fw = dev.info[1][f];
        if (fwname == fw ||
            // Special handling of firmware version groups
            (fw.length == fw_ver_len && fwname.slice(-1 * glob_suffix.length) == glob_suffix &&
             fwname.slice(0, fw_ver_prefix_len) == fw.slice(0, fw_ver_prefix_len))) {
          for (var ind=0; ind<devices.length; ind++) {
            if (devices[ind].device == dev.device) {
              new_bids.push(devices[ind].info[0][f]);
            }
          }
        }
      }
    });
    dev.info[0] = new_bids;
  });

  checked_dev.forEach(function(dev){
    plots[k][2].forEach(function(graph){
      graph.data.forEach(function(dot){
        if (jQuery.inArray(dot[0],dev.info[0]) >= 0) {
          var exist = false;
          res.forEach(function(res_point){
            if (res_point.label == graph.label) {
              res_point.data.push([dot[0],dot[1]]);
              exist = true; }
          });
          if (exist == false){
            res.push({label:graph.label,data:[[dot[0],dot[1]]],points:graph.points});
          }
        }
      });
    });
  });
  res.forEach(function(re){re.data.sort(function(a,b){return(a[0]-b[0])});});
  plotGraphs(jQuery("#ph"+k),jQuery("#phf"+k),res);
}

function showTooltip(x, y, contents) {
  jQuery('<div id="tooltip">' + contents + '</div>').css( {
    position: 'absolute',
    display: 'none',
    top: y + 1,
    left: x + 5,
    border: '1px solid #fdd',
    padding: '2px', 'background-color':'#ffe', opacity:0.90
  }).appendTo("body").fadeIn(200);
}

function plotGraphs(placeholder, overview, series) {
  var width = 75, // Last N points to show on main graph
      y_max = -1, // Max Y-value for group of tests
      y_min = 1000000000,
      x_max = 0;   // The last build number

  series.forEach (function (a) {
    if ('data' in a) {
      var data = a.data;
      slice = data.slice(-1 * width);
      slice.forEach(function (e) {
        y_val = parseFloat(e[1]);
        if (y_max < y_val) y_max = y_val;
        if (y_min > y_val) y_min = y_val;
        x_val = parseInt(e[0]);
        if (x_max < x_val) x_max = x_val;
      });
  }});

  options.xaxis.max = x_max;
  // XXX includes outside points if some of inside ones are disabled
  options.xaxis.min = x_max - width;

  options.yaxis.max = 1.02 * y_max;
  options.yaxis.min = 0.98 * y_min;

  options.legend.container = legend;

  plot = jQuery.plot(placeholder, series, options);
  plot_f = jQuery.plot(overview, series, options_f);
}

function onDataReceived(series) {
  var deviceContainer = jQuery("#pht"+i),
  fwContainer = jQuery("#phfw"+i);

  devices.forEach(function (dev) {
    deviceContainer.append('<input class="shift" type="checkbox" name="'+dev['device']+'" checked="checked" id="id_' + dev['device'] + '_'+ i +'">' +
      '<label for="id_'+dev['device']+'">'+dev['device']+'</label><br/>');
  });

  var prev_fw = '';
  var new_fw = '';
  fws.forEach(function(fw){
    // Combine unofficial (e.g. nightly) builds into groups.
    // Otherwise, the list becomes too long.
    if (fw.length == fw_ver_len && fw.substr(8,2) != '00') {
      new_fw = fw.substr(0, fw_ver_len - glob_suffix.length) + glob_suffix;
    } else {
      new_fw = fw;
    }
    if (prev_fw != new_fw) {
      fwContainer.append('<input class="shift" type="checkbox" name="'+ new_fw +'" checked="checked" id="fwid_'+ new_fw +'_'+ i +'">'+'<label for="fwid_'+ new_fw +'">'+ new_fw +'</label><br/>');
      prev_fw = new_fw;
    }
  });

  plotGraphs(placeholder, placeholder_f, series);
  plots.push([plot,plot_f,series]);
  }
})
