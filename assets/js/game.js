export default {
  mounted() {
    const canvas = this.el;
    const ctx = canvas.getContext('2d');
    let state = { players: {}, current_letter: null };
    const boxLengthWidth = 40;

    this.handleEvent('game_update', (newState) => {
      state = newState;
    });

    const letterSize = 48;
    ctx.font = `${letterSize}px Arial`;

    const draw = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      if (state.current_letter) {
        ctx.fillStyle = 'white';
        ctx.strokeStyle = 'black';
        ctx.lineWidth = 4;

        const {
          char,
          position: [lX, lY],
        } = state.current_letter;

        const letterX = lX - letterSize / 2;
        const letterY = lY + letterSize / 2;

        ctx.strokeText(char, letterX, letterY);
        ctx.fillText(char, letterX, letterY);
      }

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
