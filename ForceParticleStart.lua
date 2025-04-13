
wait(1)
-- this needs to run after PreloadAssets

-- This emits a bunch of particles right away 

local emitters = {
	workspace.CentralMagic8Ball.ball.ParticleEmitterBallSparkles,
	workspace.CentralMagic8Ball.ball.ParticleEmitterQuestionMarks,
	workspace.FieldParticles.ParticleEmitterFieldWisps -- Adjust name/path if different
}
for _, emitter in pairs(emitters) do
	emitter:Emit(5) -- Burst 5 particles instantly
	print("emitting:", emitters)
end