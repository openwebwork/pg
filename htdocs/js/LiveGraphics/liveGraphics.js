'use strict';

(() => {
	// Convenience method for easily constructing nested x3dom elements with code that clearly reveals the structure.
	const createX3DElement = (type, attributes = null, ...children) => {
		const element = document.createElement(type);
		if (attributes) {
			for (const [attribute, value] of Object.entries(attributes)) {
				element.setAttribute(attribute, value);
			}
		}
		element.append(...children);
		return element;
	};

	const liveGraphics3D = (container) => {
		const options = JSON.parse(container.dataset.options);

		// Set default options.
		options.width = options.width ?? 200;
		options.height = options.height ?? 200;
		options.showAxes = options.showAxes ?? false;
		options.showAxesCube = options.showAxesCube ?? true;
		options.numTicks = options.numTicks ?? 4;
		options.tickSize = options.tickSize ?? 0.1;
		options.tickFontSize = options.tickFontSize ?? 0.15;
		options.axisKey = options.axisKey ?? ['X', 'Y', 'Z'];
		options.drawMesh = options.drawMesh ?? true;

		// Define the x3d element and scene.
		const x3d = createX3DElement('x3d', { width: `${options.width}px`, height: `${options.height}px` });
		container.append(x3d);

		const screenReaderOnly = document.createElement('span');
		screenReaderOnly.classList.add('visually-hidden');
		screenReaderOnly.textContent = 'A manipulable 3d graph.';
		container.append(screenReaderOnly);

		const scene = createX3DElement('scene');
		x3d.append(scene);

		// Arrays of colors and thicknesses drawn from input.
		const colors = {};
		const lineThickness = {};

		// Scale elements capturing scale of plotted data.
		let windowScale = 0;
		let coordMins;
		let coordMaxs;

		// Block indexes are used to associate objects to colors and thicknesses.
		let blockIndex = 0;
		let surfaceBlockIndex = 0;

		// Data from input.
		const surfaceCoords = [];
		const surfaceIndex = [];
		const lineCoords = [];
		const points = [];
		const labels = [];

		let variables = '';

		// This is the color map for shading surfaces based on elevation.
		const colormap = [
			[0.0, 0.0, 0.5],
			[0.0, 0.0, 0.56349],
			[0.0, 0.0, 0.62698],
			[0.0, 0.0, 0.69048],
			[0.0, 0.0, 0.75397],
			[0.0, 0.0, 0.81746],
			[0.0, 0.0, 0.88095],
			[0.0, 0.0, 0.94444],
			[0.0, 0.00794, 1.0],
			[0.0, 0.07143, 1.0],
			[0.0, 0.13492, 1.0],
			[0.0, 0.19841, 1.0],
			[0.0, 0.2619, 1.0],
			[0.0, 0.3254, 1.0],
			[0.0, 0.38889, 1.0],
			[0.0, 0.45238, 1.0],
			[0.0, 0.51587, 1.0],
			[0.0, 0.57937, 1.0],
			[0.0, 0.64286, 1.0],
			[0.0, 0.70635, 1.0],
			[0.0, 0.76984, 1.0],
			[0.0, 0.83333, 1.0],
			[0.0, 0.89683, 1.0],
			[0.0, 0.96032, 1.0],
			[0.02381, 1.0, 0.97619],
			[0.0873, 1.0, 0.9127],
			[0.15079, 1.0, 0.84921],
			[0.21429, 1.0, 0.78571],
			[0.27778, 1.0, 0.72222],
			[0.34127, 1.0, 0.65873],
			[0.40476, 1.0, 0.59524],
			[0.46825, 1.0, 0.53175],
			[0.53175, 1.0, 0.46825],
			[0.59524, 1.0, 0.40476],
			[0.65873, 1.0, 0.34127],
			[0.72222, 1.0, 0.27778],
			[0.78571, 1.0, 0.21429],
			[0.84921, 1.0, 0.15079],
			[0.9127, 1.0, 0.0873],
			[0.97619, 1.0, 0.02381],
			[1.0, 0.96032, 0.0],
			[1.0, 0.89683, 0.0],
			[1.0, 0.83333, 0.0],
			[1.0, 0.76984, 0.0],
			[1.0, 0.70635, 0.0],
			[1.0, 0.64286, 0.0],
			[1.0, 0.57937, 0.0],
			[1.0, 0.51587, 0.0],
			[1.0, 0.45238, 0.0],
			[1.0, 0.38889, 0.0],
			[1.0, 0.3254, 0.0],
			[1.0, 0.2619, 0.0],
			[1.0, 0.19841, 0.0],
			[1.0, 0.13492, 0.0],
			[1.0, 0.07143, 0.0],
			[1.0, 0.00794, 0.0],
			[0.94444, 0.0, 0.0],
			[0.88095, 0.0, 0.0],
			[0.81746, 0.0, 0.0],
			[0.75397, 0.0, 0.0],
			[0.69048, 0.0, 0.0],
			[0.62698, 0.0, 0.0],
			[0.56349, 0.0, 0.0],
			[0.5, 0.0, 0.0]
		];

		// Split a list of mathematica commands into blocks.
		const splitMathematicaBlocks = (text) => {
			let bracketcount = 0;
			const blocks = [];
			let block = '';

			for (let i = 0; i < text.length; ++i) {
				block += text.charAt(i);

				if (text.charAt(i) === '[') ++bracketcount;

				if (text.charAt(i) === ']') {
					bracketcount--;
					if (bracketcount == 0) {
						++i;
						blocks.push(block);
						block = '';
					}
				}
			}

			return blocks;
		};

		// The mathematica code comes in blocks enclosed by braces.  This code makes an array from those blocks.
		// The largest of them will be the polygon block which defines the surface.
		const recurseMathematicaBlocks = (text, initialcount) => {
			let bracketcount = 0;
			const blocks = [];
			let block = '';

			if (initialcount) {
				bracketcount = initialcount;
			}

			for (let i = 0; i < text.length; ++i) {
				if (text.charAt(i) === '{') {
					++bracketcount;
				}

				if (bracketcount > 0) {
					block += text.charAt(i);
				}

				if (text.charAt(i) === '}') {
					bracketcount--;
					if (bracketcount == 0) {
						blocks.push(block.substring(1, block.length - 1));
						block = '';
					}
				}
			}

			return blocks;
		};

		const parseMathematicaBlocks = (blocks) => {
			for (const block of blocks) {
				++blockIndex;

				if (block.match(/^\s*\{/)) {
					// This is a block inside of a block.  So recurse.
					parseMathematicaBlocks(recurseMathematicaBlocks(block));
				} else if (block.match(/Point/)) {
					// Find any individual points that need to be plotted.
					// Points are defined by short blocks so don't split into individual commands.
					let str = block.match(/Point\[\s*\{\s*(-?\d*\.?\d*)\s*,\s*(-?\d*\.?\d*)\s*,\s*(-?\d*\.?\d*)\s*\}/);
					const point = {};

					if (!str) {
						console.log('Error Parsing Point');
						continue;
					}

					point.coords = [parseFloat(str[1]), parseFloat(str[2]), parseFloat(str[3])];

					str = block.match(/PointSize\[\s*(\d*\.?\d*)\s*\]/);

					if (str) {
						point.radius = parseFloat(str[1]);
					}

					str = block.match(/RGBColor\[\s*(\d*\.?\d*)\s*,\s*(\d*\.?\d*)\s*,\s*(\d*\.?\d*)\s*\]/);

					if (str) {
						point.rgb = [parseFloat(str[1]), parseFloat(str[2]), parseFloat(str[3])];
					}

					points.push(point);
				} else {
					// Otherwise its a list of commands that need to be individually processed.
					for (const command of splitMathematicaBlocks(block)) {
						if (command.match(/^\s*\{/)) {
							// This is a block inside of a block.  So recurse.
							parseMathematicaBlocks(recurseMathematicaBlocks(block));
						} else if (command.match(/Polygon/)) {
							if (!surfaceBlockIndex) surfaceBlockIndex = blockIndex;

							// Extract all points for each polygon.
							for (const pointstring of recurseMathematicaBlocks(
								command.replace(/Polygon\[([^\]]*)\]/, '$1'),
								-1
							)) {
								const splitstring = pointstring.replace(/\{([^\{]*)\}/, '$1').split(',');
								const point = [];

								for (let i = 0; i < 3; ++i) {
									point[i] = parseFloat(
										new Function(`'use strict'; { ${variables} return ${splitstring[i]} }`)()
									);
								}

								// Find the index of the point in surfaceCoords.
								// If the point is not in surfaceCoords, then add it.
								const pointIndex = surfaceCoords.findIndex(
									(p) => p[0] === point[0] && p[1] === point[1] && p[2] === point[2]
								);

								if (pointIndex === -1) {
									surfaceIndex.push(surfaceCoords.length);
									surfaceCoords.push(point);
								} else {
									surfaceIndex.push(pointIndex);
								}
							}

							surfaceIndex.push(-1);
						} else if (command.match(/Line/)) {
							// Add a line to the line array.
							const pointstrings = recurseMathematicaBlocks(
								command.replace(/Line\[([^\]]*)\],/, '$1'),
								-1
							);

							const line = [];

							try {
								for (let i = 0; i < 2; ++i) {
									pointstrings[i] = pointstrings[i].replace(/\{([^\{]*)\}/, '$1');
									const splitstring = pointstrings[i].split(',');
									const point = [];

									for (let j = 0; j < 3; ++j) {
										point[j] = parseFloat(
											new Function(`'use strict'; { ${variables} return ${splitstring[j]} }`)()
										);
									}

									line.push(point);
								}
							} catch (e) {
								console.log(`Error Parsing Line: ${e}`);
								continue;
							}

							line.push(blockIndex);
							lineCoords.push(line);
						} else if (command.match(/RGBColor/)) {
							const str = command.match(
								/RGBColor\[\s*(\d*\.?\d*)\s*,\s*(\d*\.?\d*)\s*,\s*(\d*\.?\d*)\s*\]/
							);

							colors[blockIndex] = [parseFloat(str[1]), parseFloat(str[2]), parseFloat(str[3])];
						} else if (command.match(/Thickness/)) {
							lineThickness[blockIndex] = parseFloat(command.match(/Thickness\[\s*(\d*\.?\d*)\s*\]/)[1]);
						} else if (command.match(/Text/)) {
							// Find any individual labels that need to be plotted.
							const label = {};

							const labelStr = command.match(
								/\{\s*(-?\d*\.?\d*)\s*,\s*(-?\d*\.?\d*)\s*,\s*(-?\d*\.?\d*)\s*\}/
							);
							if (!labelStr) {
								console.log('Error Parsing Label');
								continue;
							}

							label.coords = [parseFloat(labelStr[1]), parseFloat(labelStr[2]), parseFloat(labelStr[3])];

							const optionsStr = command.match(/StyleForm\[\s*(\w+),\s*FontSize\s*->\s*(\d+)\s*\]/);
							if (!optionsStr) {
								console.log('Error Parsing Label');
								continue;
							}

							label.text = optionsStr[1];
							label.fontSize = optionsStr[2];

							labels.push(label);
						}
					}
				}
			}
		};

		const parseLive3DData = (text) => {
			// Set up variables.
			for (const [name, data] of Object.entries(options.vars)) {
				variables += `const ${name} = ${data};`;
			}

			// Parse axes commands.
			if (text.match(/Axes\s*->\s*True/)) options.showAxes = true;

			const labels = text.match(/AxesLabel\s*->\s*\{\s*(\w+),\s*(\w+),\s*(\w+)\s*\}/);
			if (labels) options.axisKey = [labels[1], labels[2], labels[3]];

			// Split the input into blocks and parse.
			parseMathematicaBlocks(recurseMathematicaBlocks(text));
		};

		// Find the maximum and minimum of all mesh coordinate points and the maximum coordinate value for the scale.
		const setExtremum = () => {
			const min = [0, 0, 0];
			const max = [0, 0, 0];

			for (const point of surfaceCoords) {
				for (let i = 0; i < 3; ++i) {
					if (point[i] < min[i]) min[i] = point[i];
					else if (point[i] > max[i]) max[i] = point[i];
				}
			}

			for (const line of lineCoords) {
				for (let i = 0; i < 2; ++i) {
					for (let j = 0; j < 3; ++j) {
						if (line[i][j] < min[j]) {
							min[j] = line[i][j];
						} else if (line[i][j] > max[j]) {
							max[j] = line[i][j];
						}
					}
				}
			}

			coordMins = min;
			coordMaxs = max;

			let sum = 0;
			for (let i = 0; i < 3; ++i) {
				sum += max[i] - min[i];
			}

			windowScale = sum / 3;
		};

		// Build the ticks, tick labels, and axis label for the axis with the given index.
		const makeAxisTicks = (index) => {
			const shapes = [];

			for (let i = 0; i < options.numTicks - 1; ++i) {
				// Coordinate of tick and label
				const coord = ((coordMaxs[index] - coordMins[index]) / options.numTicks) * (i + 1) + coordMins[index];

				// Ticks are boxes defined by tickSize
				shapes.push(
					createX3DElement(
						'transform',
						{ translation: [coord, 0, 0] },
						createX3DElement(
							'shape',
							null,
							createX3DElement(
								'appearance',
								null,
								createX3DElement('material', { diffuseColor: 'black' })
							),
							createX3DElement('box', {
								size: `${options.tickSize} ${options.tickSize} ${options.tickSize}`
							})
						)
					)
				);

				// Labels have two decimal places and always point towards view.
				shapes.push(
					createX3DElement(
						'transform',
						{ translation: [coord, 0.1, 0] },
						createX3DElement(
							'billboard',
							{ axisOfRotation: '0 0 0' },
							createX3DElement(
								'shape',
								null,
								createX3DElement(
									'appearance',
									null,
									createX3DElement('material', { diffuseColor: 'black' })
								),
								createX3DElement(
									'text',
									{ string: coord.toFixed(2), solid: 'true' },
									createX3DElement('fontstyle', {
										size: options.tickFontSize * windowScale,
										family: 'mono',
										style: 'bold',
										justify: 'MIDDLE'
									})
								)
							)
						)
					)
				);
			}

			// Add the axis label to the end of the axis.
			shapes.push(
				createX3DElement(
					'transform',
					{ translation: [coordMaxs[index], 0.1, 0] },
					createX3DElement(
						'billboard',
						{ axisOfRotation: '0 0 0' },
						createX3DElement(
							'shape',
							null,
							createX3DElement(
								'appearance',
								null,
								createX3DElement('material', { diffuseColor: 'black' })
							),
							createX3DElement(
								'text',
								{ string: options.axisKey[index], solid: 'true' },
								createX3DElement('fontstyle', {
									size: options.tickFontSize * windowScale,
									family: 'mono',
									style: 'bold',
									justify: 'MIDDLE'
								})
							)
						)
					)
				)
			);

			return shapes;
		};

		const drawAxes = () => {
			// Build the x axis and add the ticks.
			scene.append(
				createX3DElement(
					'transform',
					{ translation: [0, coordMins[1], coordMins[2]] },
					createX3DElement(
						'group',
						null,
						createX3DElement(
							'shape',
							null,
							createX3DElement(
								'appearance',
								null,
								createX3DElement('material', { emissiveColor: 'black' })
							),
							createX3DElement('Polyline2D', { lineSegments: coordMins[0] + ' 0 ' + coordMaxs[0] + ' 0' })
						),
						...makeAxisTicks(0)
					)
				)
			);

			if (options.showAxesCube) {
				for (const translation of [
					[0, coordMins[1], coordMaxs[2]],
					[0, coordMaxs[1], coordMins[2]],
					[0, coordMaxs[1], coordMaxs[2]]
				]) {
					scene.append(
						createX3DElement(
							'transform',
							{ translation },
							createX3DElement(
								'shape',
								null,
								createX3DElement(
									'appearance',
									null,
									createX3DElement('material', { emissiveColor: 'black' })
								),
								createX3DElement('Polyline2D', {
									lineSegments: coordMins[0] + ' 0 ' + coordMaxs[0] + ' 0'
								})
							)
						)
					);
				}
			}

			// Build the y axis and add the ticks.
			scene.append(
				createX3DElement(
					'transform',
					{ translation: [coordMins[0], 0, coordMins[2]], rotation: [0, 0, 1, Math.PI / 2] },
					createX3DElement(
						'group',
						null,
						createX3DElement(
							'shape',
							null,
							createX3DElement(
								'appearance',
								null,
								createX3DElement('material', { emissiveColor: 'black' })
							),
							createX3DElement('Polyline2D', { lineSegments: coordMins[1] + ' 0 ' + coordMaxs[1] + ' 0' })
						),
						...makeAxisTicks(1)
					)
				)
			);

			if (options.showAxesCube) {
				for (const translation of [
					[coordMins[0], 0, coordMaxs[2]],
					[coordMaxs[0], 0, coordMins[2]],
					[coordMaxs[0], 0, coordMaxs[2]]
				]) {
					scene.append(
						createX3DElement(
							'transform',
							{ translation, rotation: [0, 0, 1, Math.PI / 2] },
							createX3DElement(
								'shape',
								null,
								createX3DElement(
									'appearance',
									null,
									createX3DElement('material', { emissiveColor: 'black' })
								),
								createX3DElement('Polyline2D', {
									lineSegments: coordMins[1] + ' 0 ' + coordMaxs[1] + ' 0'
								})
							)
						)
					);
				}
			}

			// Build the z axis and add the ticks.
			scene.append(
				createX3DElement(
					'transform',
					{ translation: [coordMins[0], coordMins[1], 0], rotation: [0, 1, 0, -Math.PI / 2] },
					createX3DElement(
						'group',
						null,
						createX3DElement(
							'shape',
							null,
							createX3DElement(
								'appearance',
								null,
								createX3DElement('material', { emissiveColor: 'black' })
							),
							createX3DElement('Polyline2D', { lineSegments: coordMins[2] + ' 0 ' + coordMaxs[2] + ' 0' })
						),
						...makeAxisTicks(2)
					)
				)
			);

			if (options.showAxesCube) {
				for (const translation of [
					[coordMins[0], coordMaxs[1], 0],
					[coordMaxs[0], coordMins[1], 0],
					[coordMaxs[0], coordMaxs[1], 0]
				]) {
					scene.append(
						createX3DElement(
							'transform',
							{ translation, rotation: [0, 1, 0, -Math.PI / 2] },
							createX3DElement(
								'shape',
								null,
								createX3DElement(
									'appearance',
									null,
									createX3DElement('material', { emissiveColor: 'black' })
								),
								createX3DElement('Polyline2D', {
									lineSegments: coordMins[2] + ' 0 ' + coordMaxs[2] + ' 0'
								})
							)
						)
					);
				}
			}
		};

		const drawSurface = () => {
			if (surfaceCoords.length == 0) return;

			let coordstr = '';
			let indexstr = '';
			let colorstr = '';
			let colorindstr = '';

			// Build a string with all the surface coodinates.
			for (const point of surfaceCoords) {
				coordstr += point.join(' ') + ' ';
			}

			// Build a string with all the surface indexes.  At the same time build
			// a string with color data and the associated color indexes.
			for (const index of surfaceIndex) {
				indexstr += index + ' ';

				if (index == -1) {
					colorindstr += '-1 ';
					continue;
				}

				let cindex = parseInt(
					((surfaceCoords[index][2] - coordMins[2]) / (coordMaxs[2] - coordMins[2])) * colormap.length
				);

				if (cindex == colormap.length) {
					--cindex;
				}

				colorindstr += cindex + ' ';
			}

			for (const color of colormap) {
				for (let i = 0; i < 3; ++i) {
					color[i] += 0.2;
					color[i] = Math.min(color[i], 1);
				}

				colorstr += color[0] + ' ' + color[1] + ' ' + color[2] + ' ';
			}

			let flatcolor = false;
			let color = [];

			if (surfaceBlockIndex in colors) {
				flatcolor = true;
				color = colors[surfaceBlockIndex];
			}

			// Add surface to scene as an indexedfaceset
			const surface = createX3DElement(
				'shape',
				null,
				createX3DElement(
					'appearance',
					null,
					createX3DElement('material', {
						ambientIntensity: '0',
						convex: 'false',
						creaseangle: Math.PI,
						diffusecolor: color,
						shininess: '.015'
					})
				)
			);

			const indexedfaceset = createX3DElement(
				'indexedfaceset',
				{ coordindex: indexstr, solid: 'false' },
				createX3DElement('coordinate', { point: coordstr })
			);

			if (!flatcolor) {
				indexedfaceset.setAttribute('colorindex', colorindstr);
				indexedfaceset.append(createX3DElement('color', { color: colorstr }));
			}

			// Append the indexed face set to the shape after it is assembled.
			// Otherwise sometimes x3d tries to access the various data before its ready.
			surface.append(indexedfaceset);

			scene.append(surface);

			if (options.drawMesh) {
				scene.append(
					createX3DElement(
						'shape',
						null,
						createX3DElement('appearance', null, createX3DElement('material', { diffusecolor: [0, 0, 0] })),
						createX3DElement(
							'indexedlineset',
							{ coordindex: indexstr, solid: 'true' },
							createX3DElement('coordinate', { point: coordstr })
						)
					)
				);
			}
		};

		const drawLines = () => {
			if (lineCoords.length == 0) return;

			const lineGroup = createX3DElement('group');

			for (const line of lineCoords) {
				// Lines are cylinders that start centered at the origin along the y axis.
				// They need to be translated and rotated into place.
				const length = Math.sqrt(
					Math.pow(line[0][0] - line[1][0], 2) +
						Math.pow(line[0][1] - line[1][1], 2) +
						Math.pow(line[0][2] - line[1][2], 2)
				);
				if (length == 0) continue;

				const rotation = [];
				rotation[0] = line[1][2] - line[0][2];
				rotation[1] = 0;
				rotation[2] = line[0][0] - line[1][0];
				rotation[3] = Math.acos((line[1][1] - line[0][1]) / length);

				const translation = [0, 0, 0];

				for (let i = 0; i < 3; ++i) {
					translation[i] = (line[1][i] + line[0][i]) / 2;
				}

				let color = [0, 0, 0];
				let radius = 0.005;

				if (line[2] in colors) color = colors[line[2]];
				if (line[2] in lineThickness) radius = Math.max(lineThickness[line[2]], 0.005);

				lineGroup.append(
					createX3DElement(
						'transform',
						{ translation, rotation },
						createX3DElement(
							'shape',
							null,
							createX3DElement('appearance', null, createX3DElement('material', { diffusecolor: color })),
							createX3DElement('Cylinder', { height: length, radius: radius * 2 })
						)
					)
				);
			}

			scene.append(lineGroup);
		};

		const drawPoints = () => {
			for (const point of points) {
				// Points are drawn as spheres.
				scene.append(
					createX3DElement(
						'transform',
						{ translation: point.coords },
						createX3DElement(
							'shape',
							null,
							createX3DElement(
								'appearance',
								null,
								createX3DElement('material', { diffuseColor: point.rgb ?? 'black' })
							),
							createX3DElement('sphere', { radius: point.radius * 2.25 })
						)
					)
				);
			}
		};

		const drawLabels = () => {
			for (const label of labels) {
				// The text is a billboard that automatically faces the user.
				scene.append(
					createX3DElement(
						'transform',
						{ translation: label.coords },
						createX3DElement(
							'billboard',
							{ axisOfRotation: '0 0 0' },
							createX3DElement(
								'shape',
								null,
								createX3DElement(
									'appearance',
									null,
									createX3DElement('material', { diffuseColor: 'black' })
								),
								createX3DElement(
									'text',
									{ string: label.text, solid: 'true' },
									createX3DElement('fontstyle', {
										// Mathematica label sizes are fontsizes, where
										// the units for x3dom are local coordinate sizes.
										size: label.size ? label.size / (1.5 * windowScale) : '.5',
										family: 'mono',
										justify: 'MIDDLE'
									})
								)
							)
						)
					)
				);
			}
		};

		// Intialization function.  This takes the mathmatica data string and actually sets up the
		// dom structure for the graph.  The actual graphing is done automatically by x3dom.
		const initialize = (datastring) => {
			// Parse matlab string.
			parseLive3DData(datastring);

			// Find extremum for axis and window scale.
			setExtremum();

			// Set up scene veiwpoint to be along the x axis looking to the origin.
			scene.append(
				createX3DElement(
					'transform',
					{ rotation: [1, 0, 0, Math.PI / 2] },
					createX3DElement('viewpoint', {
						fieldofview: 0.9,
						position: [2 * windowScale, 0, 0],
						orientation: [0, 1, 0, Math.PI / 2]
					})
				)
			);

			scene.append(createX3DElement('background', { skycolor: '1 1 1' }));

			// Draw components of scene
			if (options.showAxes) drawAxes();
			drawSurface();
			drawLines();
			drawPoints();
			drawLabels();
		};

		// This section of code is run whenever the object is created.  It obtains the data either from direct input, a
		// zip file, or a data file.  Then it calls intialize with the data string.

		if (options.input) {
			initialize(options.input);
		} else if (options.archive) {
			// If an archive file is provided then retrieve that file.
			// The file name is the file inside the archive that contains the data.
			JSZipUtils.getBinaryContent(options.archive, (error, data) => {
				if (error) {
					console.log(error);
					container.innerHTML = 'Failed to get input archive';
				}

				JSZip.loadAsync(data).then((zip) => {
					zip.file(options.file)
						.async('string')
						.then((string) => initialize(string));
				});
			});
		} else if (options.file) {
			fetch(options.file)
				.then((response) => (response.ok ? response.text() : response))
				.then((data) => initialize(data))
				.catch((error) => {
					console.log(error);
					container.innerHTML = 'Failed to get input file';
				});
		} else {
			container.innerHTML = 'No input data provided';
		}
	};

	// Deal with live graphics 3d elements that are already on the page.
	document.querySelectorAll('.live-graphics-3d-container').forEach(liveGraphics3D);

	// Deal with live graphics 3d elements that are added to the page later.
	const observer = new MutationObserver((mutationsList) => {
		mutationsList.forEach((mutation) => {
			mutation.addedNodes.forEach((node) => {
				if (node instanceof Element) {
					if (node.classList.contains('live-graphics-3d-container')) liveGraphics3D(node);
					else node.querySelectorAll('.live-graphics-3d-container').forEach(liveGraphics3D);
				}
			});
		});
	});
	observer.observe(document.body, { childList: true, subtree: true });
})();
