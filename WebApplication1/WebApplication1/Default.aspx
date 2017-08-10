<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="WebApplication1._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <!doctype html>
    <script src="https://code.highcharts.com/highcharts.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
     <script src="https://code.highcharts.com/highcharts.js"></script>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
        #container{
	        min-width: 420px;
	        background-color: white;
            display: flex;
            flex-direction: column;
            border-radius: 2px;
            padding: 10px;
            box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.14), 0 1px 5px 0 rgba(0, 0, 0, 0.12), 0 3px 1px -2px rgba(0, 0, 0, 0.2);
        }

        .canvas {
            margin:5px 0 5px 0;
            /*border-radius: 2px;
            border: 1px inset rgb(200,200,200);
	        background-color: #ECEFF1;*/
			    min-width: 400px;
    max-width: 400px;
    height: 180px;
        }

        .chart {

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
    <span style="overflow: hidden;white-space: nowrap;text-overflow: ellipsis;" id="percentExpected" class="progressHeader"> 0% Loading SfWfaRuntime</span>
    <div class="canvas" id="chartContainer"></div>
    <span id="latestFileName" style="overflow: hidden;white-space: nowrap;text-overflow: ellipsis;">Last Item: component.js</span>
    <span style="overflow: hidden;white-space: nowrap;text-overflow: ellipsis;" id="timeRemaining">Time Remaining: About 45s</span>


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




            //gets the init data
            function getInitDataFromPerformanceEntries() {
                var initEntries = performance.getEntriesByType("resource");
                var data = [];
                data[0] = [0, 0];
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

            //Handles new data as it comes in
            var nextDataPoints = [];
            var expectedTime = 45;
            var actionName = "SfWfaRuntime";
            var percentMax = false;
            var amountShowing = 5;
            var dbConnection;

            function stopLoady() {
                //called directly
            };

            function startLoady(actionName) {

            };


            
            async function setHistoricTimings(action, subActions) {
                const connection = await getConnection();
                writeActionData(action);
                write(subActions);
            };


            //fire at the start to get data
            //data should be in the format { actionName: , avg:, min:, max:,subAction: [] }
            //                             subActions{ actionName: , subActionName:, avg:, min:, max:}
            async function getHistoricTimings(actionName) {
                    const connection = await getConnection();
                    const pDefaultActionData = readActionData(connection, "Default");
                    const pActionData = readActionData(connection, actionName);
                    const pSubActionData = readSubActionData(connection, actionName);

                    const defaultActionData = await pDefaultActionData;
                    const actionData = await pDefaultActionData;
                    const subActionData = await pDefaultActionData;

                    if (actionData === null) {
                        return defaultActionData;
                    } else {
                        return { actionData: actionData, subActionData: subActionData };
                    }
            };


            //promise to get db connection + setup.
            function getConnection() {
                return new Promise(function (resolve, reject) {
                    if (dbConnection != undefined) {
                        resolve(dbConnection);
                    }
                    var request = indexedDB.open("loady", 1);
                    request.onupgradeneeded((event) => {

                        if (event.oldVersion < 1) {
                            //create store for actions
                            var actionStore = db.createObjectStore("actions", { keyPath: "actionName" });
                            actionStore.put({ actionName: "Default", avg: 5, max: 10, min: 2 });

                            //create store for long running subActions
                            var subActionStore = db.createObjectStore("subActions", { keyPath: "subActionName" });
                            subActionStore.createIndex("by_actionName", "actionName", { unique: false });

                            subActionStore.put({ actionName: "Default", subActionName: "Default", avg: 5, max: 10, min: 2 });
                        }
                    });

                    request.onsuccess(() => {
                        dbConnection = request.result;
                        resolve(dbConnection);
                    });
                })
            };

            function readActionData(db, actionName) {
                return new Promise((resolve, reject) => {

                    var tx = db.transaction("actions", "readonly");
                    var store = tx.objectStore("actions");
                    var request = store.get(actionName);

                    request.onerror(() => {
                        resolve(null);
                    });

                    request.onsuccess(() => {
                        resolve(request.result);
                    });

                });
            };

            function writeActionData(db, actionData) {
                var tx = db.transaction("actions", "readwrite");
                var store = tx.objectStore("actions");
                var deleteRequest = store.delete(actionData.actionName);
                deleteRequest.onsuccess(() => {
                    store.put(actionData);
                });
            };

            function writeSubActionData(db, subActionData) {
                var tx = db.transaction("subActions", "readwrite");
                var store = tx.objectStore("subActions");

                subActionData.forEach((item) => {
                    var deleteRequest = store.delete(item.subActionName);
                    deleteRequest.onsuccess(() => {
                        store.put(item);
                    });
                });
            };


            function readSubActionData(db, actionName) {
                return new Promise((resolve, reject) => {
                    var tx = db.transaction("subActions", "readonly");
                    var store = tx.objectStore("subActions");
                    var index = store.index("by_actionName");

                    var request = index.openCursor(IDBKeyRange.only(actionName));
                    request.onsuccess(() => {
                        var subActionData = [];
                        var cursor = request.result;
                        if (cursor) {
                            // Called for each matching record.
                            subActionData.push(cursor.value);
                            cursor.continue();
                        } else {
                            // No more matching records.
                            report(null);
                        }

                        resolve(subActionData);
                    });
                });
            };


            function checkForDataBaseSupport() {
                //check for support
                if (!('indexedDB' in window)) {
                    stopLoady();
                    return;
                }
            };



            //timer event for updating the graph + text.
            function updateRemainingTimeAndHeader(series, localYAxis) {

                //get timings
                var perfTime = performance.now() / 1000;
                var newTime = Math.round(expectedTime - perfTime);
                var position = Math.round(perfTime);


                //add zero time points to the graph (aka heartbeat)
                if (nextDataPoints[position] == null) {
                    nextDataPoints[position] = [position, 0];
                } else {
                    nextDataPoints[position] = [position, nextDataPoints[position][1] + 0];
                }


                //render the data points
                var dataPointsWithValue = nextDataPoints.filter(function (value) { return value != undefined });
                if (dataPointsWithValue.length > 1) {
                    var toAdd = dataPointsWithValue.slice(0, dataPointsWithValue.length - 1);
                    for (var i = 0; i < toAdd.length; i++) {

                        var shift = series.data.length > amountShowing;

                        series.addPoint(toAdd[i], true, shift);
                    }
                    nextDataPoints = nextDataPoints.slice(nextDataPoints.length - 1, 1);
                }




                if (!percentMax) {
                    var perecent = Math.round(perfTime / expectedTime * 100);
                    if (perecent > 100) {
                        perecent = 99;
                        percentMax = true;
                    }
                    document.getElementById("percentExpected").innerText = perecent + "% Loading " + actionName;
                }

                if (newTime < 3) {
                    document.getElementById("timeRemaining").innerText = "Time Remaining: Less than 3s";

                } else {
                    document.getElementById("timeRemaining").innerText = "Time Remaining: About " + newTime + "s";
                }

                if (!series.data.some(function (item) { return item.y > 0 })) {
                    localYAxis[0].setExtremes(0, 1);
                } else {
                    localYAxis[0].setExtremes(0, null);
                }

            };


            //add items to be rendered as they get observed
            function perfObserver(series, list, observer) {

                var newEntries = list.getEntries();

                var fileNameWithProtocolRemoved = newEntries[newEntries.length - 1].name.split("?")[0].split("//")[1];

                var latestFilename = "Last Item: " + fileNameWithProtocolRemoved.substring(fileNameWithProtocolRemoved.indexOf("/") + 1);
                document.getElementById("latestFileName").innerText = latestFilename;

                //add new Entires into next DataPoints
                for (var i = 0; i < newEntries.length; i++) {
                    var position = Math.round(newEntries[i].responseEnd / 1000 + .5);
                    if (nextDataPoints[position] == null) {
                        nextDataPoints[position] = [position, newEntries[i].transferSize];
                    } else {
                        nextDataPoints[position] = [position, nextDataPoints[position][1] + newEntries[i].transferSize];
                    }
                }

                //populate it into the collection.
                //var dataPointsWithValue = nextDataPoints.filter(function (value) { return value != undefined });
                //if (dataPointsWithValue.length > 1) {
                //    var toAdd = dataPointsWithValue.slice(0, dataPointsWithValue.length - 1);
                //	for (var i = 0; i < toAdd.length; i++) {
                //		series.addPoint(toAdd[i], true, true);
                //	}
                //	nextDataPoints = nextDataPoints.slice(nextDataPoints.length - 1, 1);
                //}
            }

            //every second add a blank / update the percent / update timer





            var dataset = {
                unit: "bytes/s",
                name: "Download Activity",
                type: "area",
                data: getInitDataFromPerformanceEntries(),
                valueDecimals: 0
            };


            Highcharts.chart('chartContainer', {
                chart: {
                    marginLeft: 0, // Keep all charts left aligned
                    spacingTop: 20,
                    spacingBottom: 20,
                    events: {
                        load: function () {
                            var localSeries = this.series[0];
                            var localYAxis = this.yAxis;
                            var partialObserverProcess = function (list, observer) {
                                return perfObserver(localSeries, list, observer);
                            }
                            var observer = new PerformanceObserver(partialObserverProcess);
                            observer.observe({ entryTypes: ["resource"] });

                            let timer = setInterval(function () {
                                updateRemainingTimeAndHeader(localSeries, localYAxis);
                            }, 1000);
                        }
                    }
                },

                title: {
                    text: dataset.name,
                    align: 'left',
                    margin: 0,
                    x: 0
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
                    },
                    tickLength: 0
                },
                yAxis: {
                    title: {
                        text: null
                    },
                    labels: {
                        enabled: true
                    },
                    min: 0,
                    startOnTick: false,
                    tickLength: 0,
                    floor: 0
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
