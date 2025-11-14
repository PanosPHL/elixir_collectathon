export default {
  mounted() {
    const controller = new AbortController();
    const signal = controller.signal;

    const joystickContainer = document.getElementById('joystick-container');
    const joystickHandle = this.el;

    const view = this;

    let dragging = false;
    let origin = { x: 0, y: 0 };
    let offset = { x: 0, y: 0 };
    const containerRect = joystickContainer.getBoundingClientRect();
    const handleRect = joystickHandle.getBoundingClientRect();
    const maxDistance = containerRect.width / 2 - handleRect.width / 4;

    function start() {
      dragging = true;
      origin.x = containerRect.left + containerRect.width / 2;
      origin.y = containerRect.top + containerRect.height / 2;
    }

    function move(e) {
      if (!dragging) return;
      const touch = e.touches ? e.touches[0] : e;
      const dx = touch.clientX - origin.x;
      const dy = touch.clientY - origin.y;

      // Limit distance
      const dist = Math.min(Math.sqrt(dx * dx + dy * dy), maxDistance);
      const angle = Math.atan2(dy, dx);

      offset.x = dist * Math.cos(angle);
      offset.y = dist * Math.sin(angle);

      // Move the stick
      joystickHandle.style.transform = `translate(calc(${offset.x}px), calc(${offset.y}px))`;

      // Output normalized values (-1 to 1)
      const normalizedX = parseFloat((offset.x / maxDistance).toFixed(2));
      // Browser Y values inverse of game coordinates. (i.e. Up is -1)
      const normalizedY = parseFloat((offset.y / maxDistance).toFixed(2));

      view.pushEvent('joystick_move', { x: normalizedX, y: normalizedY });
    }

    function end() {
      dragging = false;
      offset = { x: 0, y: 0 };
      joystickHandle.style.transform = '';

      view.pushEvent('joystick_move', { x: 0, y: 0 });
    }

    joystickHandle.addEventListener('mousedown', start, { signal });
    joystickHandle.addEventListener('touchstart', start, { signal });
    window.addEventListener('mousemove', move, { signal });
    window.addEventListener('touchmove', move, { signal });
    window.addEventListener('mouseup', end, { signal });
    window.addEventListener('touchend', end, { signal });
  },
};
