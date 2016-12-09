libs
cytoscapeTelescopeJs
	^ 'function visuWithId(aVisuId){
  for(var i in visus){
    if(visus[i].visuId == aVisuId)
      return visus[i].visu;
  }
}

(function(){
  var wsUri = "ws://" + location.hostname + ":1701";
  
  function init() {
    visuDivs = document.getElementsByClassName("telescopeVisu");
    visus = [];
    waitingDivByVisu = [];
    
    for(var i=0; i<visuDivs.length;i++){
      visus.push({visuId: visuDivs[i].getAttribute(''id''), visu:createVisu(visuDivs[i])});
    }
    
    websocket = new WebSocket(wsUri);
    parametrizeWebsocket(visus);
    
    for(var j in visus)
      parametrizeInteractionsListenerForVisu(visus[j]);
  }
  
  function createVisu(visuDiv){
    //Here we remove the second child which is the waiting display and store it for future waiting
    waitingDivByVisu[visuDiv.getAttribute(''id'')]=visuDiv.getElementsByClassName(''tlWaiting'')[0];
    //visuDiv.removeChild(waitingDivByVisu[aDivId]);
    return cytoscape({
      container: visuDiv.firstChild,
      layout: {name: ''preset''}
    });
  }
  
  function calculateNodesPositionsWithLayout(layout, nodes){
    
  }
  
  function parametrizeWebsocket(visus) {
    websocket.onopen = function(evt) { onOpen(evt, visus); };
    websocket.onclose = function(evt) { onClose(evt); };
    websocket.onmessage = function(evt) { onMessage(evt); };
    websocket.onerror = function(evt) { onError(evt); };
  }

  function onOpen(evt, visus) {
    messages = [];
    for (var i in visus)
      messages.push({id:visus[i].visuId, command:"generate"});

    websocket.send(JSON.stringify(messages));
  }

  function onClose(evt) {
   
  }
  
  function removeWaitingForVisuId(aVisuId){
    try{
      waitingDivByVisu[aVisuId].parentNode.removeChild(waitingDivByVisu[aVisuId]);
    }catch(err){
      //Here the waiting has been removed a previous time
    }
  }

  commandsAction={};
  
  commandsAction.add = function (command, visu) {
    elements = visu.add(command.parameters);
    for (var elementId = 0; elementId < elements.length; elementId++) {
      customizeElement(elements[elementId], command.parameters[elementId]);
    }
  };
  
  commandsAction.remove = function (command, visu) {
    visu.remove(visu.getElementById(command.nodeId));
  };
  
  commandsAction.positioning = function (command, visu) {
    visu.layout(command.layout);
  };
  
  commandsAction.customize = function (command, visu) {
    visu.getElementById(command.elementId).style(command.style);
  };
  
  commandsAction.addStaticLegendEntry = function (command) {
    addStaticLegendEntry(command.visuId,command.html);
  };
  
  commandsAction.removeLegend = function (command) {
    $(''#''+command.visuId+''legend'').remove();
  };
  
  commandsAction.callback = function (command, visu) {
    sendCallBack(command.callbackUrl, command.openInNewTab);
  };

  function onMessage(evt) {
    commands = JSON.parse(evt.data);
    
    for (var i in commands) {
      command = commands[i];
      visu = visuWithId(command.visuId);
      if (commandsAction[command.command]) {
        commandsAction[command.command](command, visu);
      } else {
        console.log("unsupported command: " + command.command);
        console.log(command);
      }
    }
    removeWaitingForVisuId(commands[0].visuId);
  }
  
  function post(path, cbId, openInNewTab) {
    var form = $(''<form></form>'',{method: "post",action: path});
    if (openInNewTab) {
      form.attr("target", "_blank");
    }
    
    var field = $(''<input>'',{ type: "hidden",name: cbId, value:''refresh''});
    form.append(field);

    // The form needs to be a part of the document in
    // order for us to be able to submit it.
    $(document.body).append(form);
    form.submit();
  }
  
  function sendCallBack(callBackUrl,openInNewTab){
    post(callBackUrl[0], callBackUrl[1], openInNewTab);
  }
  
  function customizeElement(element, commandParametersForElement){
    // here we define the attribute for mouse over to avoid sending request to the server if unnecessary
    if((commandParametersForElement.mouseOverInteraction !== null))
      element[''mouseOverInteraction''] = commandParametersForElement.mouseOverInteraction;
    // here we define the attribute for mouse over to avoid sending request to the server if unnecessary
    if((commandParametersForElement.dropInteraction !== null))
      element[''dropInteraction''] = commandParametersForElement.dropInteraction;
    // here we define a popup if the element has one
    if(commandParametersForElement.popUp){
      element.qtip(commandParametersForElement.popUp);
    }
    // here we define a menu if element has one
    if(commandParametersForElement.menu){
      element[''menu''] = commandParametersForElement.menu;
    }
  }
  
  function addStaticLegendEntry(visuId,html){
    var div = document.getElementById(visuId+''legend'');
    if(!div) {
      div =$(''<div>'', {id: visuId+''legend'',class :''tlLegend''})
              .html(''<table></table>'')[0];
      document.getElementById(visuId).appendChild(div);}
    div.firstChild.insertRow(-1).innerHTML = html;
  }

  function onError(evt) {
  }

 function displayMenuForElement(element, visuId, position){
    var menu = [];
    var fun = function (name, evt){
        websocket.send(JSON.stringify([
          {"id": visuId, 
          "drawableId": element.id(),
          "command": "menuInteraction",
          "kind": "menu",
          "entry": ($(evt.target).index() + 1)
          }]));};
    
    var subFun = function (name, evt){
        var selected = evt.currentTarget;
        websocket.send(JSON.stringify([
          {"id": visuId, 
          "drawableId": element.id(),
          "command": "multiMenuInteraction",
          "kind": "menu",
          "entry": ($(selected.parentNode.parentNode).index() + 1),
          "selection": ($(selected).index() + 1)
          }]));};
    
    for(var i = 0; i < element.menu.length; i++){
      entry = {name: element.menu[i].title, title: element.menu[i].title};
      
      if (element.menu[i].subMenu){
        entry["subMenu"] = [];
        for(var j = 0; j < element.menu[i].subMenu.length; j++){
          var subMenuTitle = element.menu[i].subMenu[j];
          entry["subMenu"].push({name: subMenuTitle, title: subMenuTitle, fun: subFun});
        }
      } else {
        entry["fun"]=fun;
      }
      menu.push(entry);
    }
    $(''#''+visuId).contextMenu(menu);
     //Should remove old menu
    $(''#''+visuId).contextMenu(''open'', {top: position.y, left: position.x});
  }

  eventsWithInteractions = {''tap'':''click'' , ''cxttap'':''rightClick'' , ''mouseover'':''mouseOver'', ''mouseout'':''mouseOut''};

  function createEventFunction(visuWithId){
    return function (evt){
      // server interaction processing
      if((!evt.cyTarget[''mouseOverInteraction'']) && ((evt.type == ''mouseover'') || (evt.type == ''mouseout''))){
          
      } else{
        // menu management
        if(evt.type == ''cxttap'' && evt.cyTarget[''menu'']){
          displayMenuForElement(evt.cyTarget, visuWithId.visuId,{ x:evt.originalEvent.clientX , y: evt.originalEvent.clientY});
        }       
        websocket.send(JSON.stringify([{id:visuWithId.visuId, drawableId:evt.cyTarget.id(),command:"interaction",kind:(eventsWithInteractions[evt.type])}]));
      }
    };
  }

  function isDropActionOnANode(visuWithId, candidates, pos, droppedNode){
    var target;
      
    for(i = 0; i < candidates.length ; i++){
      var node = candidates[i];
      var bound = node.renderedBoundingBox();
      if(node != droppedNode && bound.x1 < pos.x && bound.x2 > pos.x && bound.y1 < pos.y && bound.y2 > pos.y){
        //here we found a node correctly positionned and *WARNING* we keep the last one so with the closest zIndex
        target = node;
      }
    }
    
    // if we found a target and this one has a drop interaction then we request the server
    if(target && target.dropInteraction){
      websocket.send(JSON.stringify([{id:visuWithId.visuId, nodeId:droppedNode.id(),command:"dropNode",targetNode:target.id()}]));
      return true;
    } else return false;
  }

  function createDragEventFunction(visuWithId){
    return function (evt){
      //We only send a moveNode command if it is not considered as a drop
      if(!isDropActionOnANode(visuWithId, evt.cy.elements(), this.renderedPosition(), evt.cyTarget))
        websocket.send(JSON.stringify([{id:visuWithId.visuId, nodeId:evt.cyTarget.id(),command:"moveNode",position:evt.cyTarget.position()}]));
    };
  }

  function parametrizeInteractionsListenerForVisu(visuWithId){
    visuWithId.visu.on(''tap mouseover mouseout cxttap'',''node'',createEventFunction(visuWithId));
    visuWithId.visu.on(''tap mouseover mouseout cxttap'',''edge'',createEventFunction(visuWithId));
    visuWithId.visu.on(''free'',''node'',createDragEventFunction(visuWithId));     
  }

  window.addEventListener("load", init, false);
})();'