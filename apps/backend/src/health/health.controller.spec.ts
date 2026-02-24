import { HealthController } from './health.controller';

describe('HealthController', () => {
  let controller: HealthController;

  beforeEach(() => {
    controller = new HealthController();
  });

  it('should return status ok with a timestamp', () => {
    const result = controller.check();

    expect(result.status).toBe('ok');
    expect(result.timestamp).toBeDefined();
    // Verify it's a valid ISO date string
    expect(new Date(result.timestamp).toISOString()).toBe(result.timestamp);
  });
});
