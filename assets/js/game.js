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

    // Offsets to center the letter within its hitbox
    // Magic numbers... will need to find a way to adjust dynamically
    const letterXOffset = 8;
    const letterYOffset = 42;
    ctx.font = `${letterSize}px Arial`;

    const draw = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      if (state.winner) return;

      if (state.current_letter) {
        const {
          char,
          position: [letterX, letterY],
        } = state.current_letter;

        ctx.fillStyle = 'white';
        ctx.strokeStyle = 'black';
        ctx.fillText(char, letterX + letterXOffset, letterY + letterYOffset);
        ctx.strokeText(char, letterX + letterXOffset, letterY + letterYOffset);
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
