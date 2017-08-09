<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="WebApplication1._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <!doctype html>
    <script src="https://code.highcharts.com/highcharts.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
        #container{
            display: flex;
            flex-direction: column;
            border-radius: 2px;
            padding: 10px;
            box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.14), 0 1px 5px 0 rgba(0, 0, 0, 0.12), 0 3px 1px -2px rgba(0, 0, 0, 0.2);
        }

        .canvas {
            margin:5px 0 5px 0;
            border-radius: 2px;
            border: 1px inset rgb(200,200,200);
            background-color:#ECEFF1
        }

        .chart {
    min-width: 320px;
    max-width: 800px;
    height: 220px;
    margin: 0 auto;
}

        .canvasFill {
            fill:#1464BF
        }

        .progressHeader {
            font-size: 18px;
        }


    </style>

    <br />
<div id="container">    
    <span class="progressHeader"> 53% Loading SfWfaRuntime</span>
    <div class="canvas" id="chartContainer"></div>
    <span id="latestFileName" style="">Last Item: component.js</span>
    <span>Time Remaining: About 45s</span>


        <script>
            //        $('chartContainer').bind('mousemove touchmove touchstart', function (e) {
            //    var chart,
            //        point,
            //        i,
            //        event;

            //    for (i = 0; i < Highcharts.charts.length; i = i + 1) {
            //        chart = Highcharts.charts[i];
            //        event = chart.pointer.normalize(e.originalEvent); // Find coordinates within the chart
            //        point = chart.series[0].searchPoint(event, true); // Get the hovered point

            //        if (point) {
            //            point.highlight(e);
            //        }
            //    }
            //});
            /**
             * Override the reset function, we don't need to hide the tooltips and crosshairs.
             */
            Highcharts.Pointer.prototype.reset = function () {
                return undefined;
            };

            /**
             * Highlight a point by showing tooltip, setting hover state and draw crosshair
             */
            Highcharts.Point.prototype.highlight = function (event) {
                this.onMouseOver(); // Show the hover marker
                this.series.chart.tooltip.refresh(this); // Show the tooltip
                this.series.chart.xAxis[0].drawCrosshair(event, this); // Show the crosshair
            };

            /**
             * Synchronize zooming through the setExtremes event handler.
             */
            function syncExtremes(e) {
                var thisChart = this.chart;

                if (e.trigger !== 'syncExtremes') { // Prevent feedback loop
                    Highcharts.each(Highcharts.charts, function (chart) {
                        if (chart !== thisChart) {
                            if (chart.xAxis[0].setExtremes) { // It is null while updating
                                chart.xAxis[0].setExtremes(e.min, e.max, undefined, false, { trigger: 'syncExtremes' });
                            }
                        }
                    });
                }
            };

            function getInitDataFromPerformanceEntries(){
                var initEntries = performance.getEntriesByType("resource");
                var data = [];
                data[0] = [0,0];
                for (var i = 0; i < initEntries.length; i++) {
                    var position = Math.round(initEntries[i].responseEnd / 1000 + .5);
                    if (data[position] == null) {
                        data[position] = [position, initEntries[i].transferSize];
                    } else {
                        data[position] = [position, data[position][1] + initEntries[i].transferSize];
                    }
                    
                }
                return data.filter(function (value) { return value != undefined });
            };

            var nextDataPoints = [];
            function perfObserver(series, list, observer) {
                
                var newEntries = list.getEntries();
                var latestFilename = "Last Item:" + newEntries[newEntries.length - 1].name.split("?")[0].split("//")[1].split("/")[1];
                document.getElementById("latestFileName").innerText = latestFilename;

                for (var i = 0; i < newEntries.length; i++) {
                    var position = Math.round(newEntries[i].responseEnd / 1000 + .5);
                    if (nextDataPoints[position] == null) {
                        nextDataPoints[position] = [position, newEntries[i].transferSize];
                    } else {
                        nextDataPoints[position] = [position, nextDataPoints[position][1] + newEntries[i].transferSize];
                    }
                }
                var dataPointsWithValue = nextDataPoints.filter(function (value) { return value != undefined });
                if (dataPointsWithValue.length > 1) {
                    var toAdd = dataPointsWithValue.slice(0, dataPointsWithValue.length - 1)
                    for (var i = 0; i < toAdd.length; i++) {
                        series.addPoint(toAdd[i], true, true);
                    }
                }
                var nextDataPoints = nextDataPoints.slice(nextDataPoints.length - 1, 1);
            }


            var dataset = {
                unit: "bytes",
                name: "Download Rate",
                type: "area",
                data: getInitDataFromPerformanceEntries(),
                valueDecimals: 0
            };


            Highcharts.chart('chartContainer', {
                chart: {
                    marginLeft: 40, // Keep all charts left aligned
                    spacingTop: 20,
                    spacingBottom: 20,
                    events: {
                        load: function () {
                            var localSeries = this.series[0];
                            var partialObserverProcess = function (list, observer) {
                                return perfObserver(localSeries, list, observer);
                            }
                            var observer = new PerformanceObserver(partialObserverProcess);
                            observer.observe({ entryTypes: ["resource"] });
                        }
                    }
                },
                
                title: {
                    text: dataset.name,
                    align: 'left',
                    margin: 0,
                    x: 30
                },
                credits: {
                    enabled: false
                },
                legend: {
                    enabled: false
                },
                xAxis: {
                    crosshair: true,
                    events: {
                        setExtremes: syncExtremes
                    },
                    labels: {
                        format: '{value} sec'
                    }
                },
                yAxis: {
                    title: {
                        text: null
                    }
                },
                tooltip: {
                    positioner: function () {
                        return {
                            x: this.chart.chartWidth - this.label.width, // right aligned
                            y: 10 // align to title
                        };
                    },
                    borderWidth: 0,
                    backgroundColor: 'none',
                    pointFormat: '{point.y}',
                    headerFormat: '',
                    shadow: false,
                    style: {
                        fontSize: '18px'
                    },
                    valueDecimals: dataset.valueDecimals
                },
                series: [{
                    data: dataset.data,
                    name: dataset.name,
                    type: dataset.type,
                    color: Highcharts.getOptions().colors[2],
                    fillOpacity: 0.3,
                    tooltip: {
                        valueSuffix: ' ' + dataset.unit
                    }
                }]
            });


    </script>
</div>



</asp:Content>
