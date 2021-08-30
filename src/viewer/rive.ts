import * as rive from 'rive-js';

const asset = document.currentScript.attributes.getNamedItem('file');
riveInit(asset.value);

function riveInit(riveUri) {
  const canvas: HTMLCanvasElement = document.getElementById(
    'canvas'
  ) as HTMLCanvasElement;

  const artboards = document.getElementById('artboards') as HTMLDivElement;

  const animations = document.getElementById(
    'animationsDetails'
  ) as HTMLDivElement;
  const stateMachines = document.getElementById(
    'stateMachinesDetails'
  ) as HTMLDivElement;

  let riveFile = new rive.Rive({
    src: riveUri,
    autoplay: true,
    canvas: canvas,
  });

  const toc = {};
  riveFile.on(rive.EventType.Load, () => {
    for (const artboard of riveFile.contents.artboards) {
      const animations = [];
      for (const animation of artboard.animations) {
        animations.push(animation);
      }

      toc[artboard.name] = {
        animations: animations,
      };

      const artboardLink = document.createElement('a');
      artboardLink.onclick = () => {
        riveFile = new rive.Rive({
          src: asset.value,
          autoplay: true,
          canvas: canvas,
          artboard: artboard.name,
          onLoad: () => buildUi(artboard.name),
        });
      };
      artboardLink.innerText = artboard.name;
      artboards.appendChild(artboardLink);
    }
    buildUi(riveFile.activeArtboard);
  });

  function buildUi(boardName: string) {
    document.getElementById('currentArtboard').innerText =
      'Current artboard: ' + boardName;
    clearElement(animations);
    clearElement(stateMachines);
    for (const animation of toc[boardName]['animations']) {
      const row = document.createElement('div');
      const label = document.createElement('span');
      label.innerHTML = animation;
      row.append(label);
      const actionMap = {
        play: (animations: []) => riveFile.play(animations),
        stop: (animations: []) => riveFile.stop(animations),
        pause: (animations: []) => riveFile.pause(animations),
      };
      for (const action of Object.keys(actionMap)) {
        const key = action;
        const value = actionMap[key]!;
        const animationLink = document.createElement('a');
        animationLink.onclick = () => {
          value([animation]);
        };
        animationLink.innerText = key;
        row.appendChild(animationLink);
      }

      animations.appendChild(row);
    }

    const artboard = riveFile.contents.artboards.filter(artboard => {
      return artboard.name === boardName;
    })[0];

    for (const stateMachine of artboard.stateMachines) {
      const machine = document.createElement('div');
      const labelRow = document.createElement('div');
      const controlsRow = document.createElement('div');
      controlsRow.classList.add('machine-controls');

      const machineLabel = document.createElement('label');
      machineLabel.innerText = stateMachine.name;

      const machinePlay = document.createElement('a');
      machinePlay.innerHTML = 'play';
      machinePlay.onclick = () => {
        riveFile.play(stateMachine.name);
        clearElement(controlsRow);
        buildMachineUi(stateMachine.name);
      };
      const machineStop = document.createElement('a');
      machineStop.innerHTML = 'stop';
      machineStop.onclick = () => {
        clearElement(controlsRow);
        riveFile.stop(stateMachine.name);
      };

      labelRow.appendChild(machineLabel);
      labelRow.appendChild(machinePlay);
      labelRow.appendChild(machineStop);

      machine.appendChild(labelRow);
      machine.appendChild(controlsRow);
      stateMachines.appendChild(machine);
    }

    // Start the first machine.
    if (artboard.stateMachines && artboard.stateMachines.length > 0) {
      setTimeout(() => {
        const firstMachine = artboard.stateMachines[0].name;
        riveFile.play(firstMachine);
        buildMachineUi(firstMachine);
      }, 100);
    }
  }

  function buildMachineUi(name: string) {
    const controls = document.querySelector('.machine-controls') as HTMLElement;
    clearElement(controls);
    for (const input of riveFile.stateMachineInputs(name)) {
      const inputRow = document.createElement('div');
      controls.appendChild(inputRow);
      const rowLabel = document.createElement('span');
      inputRow.appendChild(rowLabel);

      rowLabel.innerText = input.name;

      if (input.type === rive.StateMachineInputType.Trigger) {
        const trigger = document.createElement('a');
        trigger.onclick = () => {
          input.fire();
        };
        trigger.innerText = 'fire';
        inputRow.appendChild(trigger);
      } else if (input.type === rive.StateMachineInputType.Boolean) {
        const trigger = document.createElement('a');
        trigger.onclick = () => {
          input.value = true;
        };
        trigger.innerText = 'trigger';
        inputRow.appendChild(trigger);
      } else if (input.type === rive.StateMachineInputType.Number) {
        const userInput = document.createElement('input');
        userInput.type = 'number';

        userInput.addEventListener('input', newValue => {
          input.value = parseInt((newValue.target as HTMLInputElement).value);
        });

        inputRow.appendChild(userInput);
      }
    }
  }
}

function clearElement(element: HTMLElement) {
  while (element.firstChild && element.removeChild(element.firstChild));
}
