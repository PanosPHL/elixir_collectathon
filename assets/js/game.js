export default {
	mounted() {
		const canvas = this.el;
		const ctx = canvas.getContext('2d');
		let state = { players: {}, current_letter: null };
		const boxLengthWidth = 40;

		this.handleEvent('game_update', (newState) => {
			state = newState;
		});

		const draw = () => {
			ctx.clearRect(0, 0, canvas.width, canvas.height);

			for (const id in state.players) {
				const player = state.players[id];
				const [playerX, playerY] = player.position;


				ctx.fillStyle = player.color;
				ctx.fillRect(playerX, playerY, boxLengthWidth, boxLengthWidth);
			}

			requestAnimationFrame(draw);
		};

		draw();
	},
};
