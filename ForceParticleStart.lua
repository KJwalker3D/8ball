
wait(1)
-- this needs to run after PreloadAssets

local emitters = {
	workspace.Magic8Ball.ball.ParticleEmitterBallSparkles,
	workspace.Magic8Ball.ball.ParticleEmitterQuestionMarks,
	workspace.Platform.Platform.ParticleEmitterStars,
	workspace.Platform.Platform.ParticleEmitterWisps,
	workspace.FieldParticles.ParticleEmitterFieldWisps -- Adjust name/path if different
}
for _, emitter in pairs(emitters) do
	emitter:Emit(5) -- Burst 5 particles instantly
	print("emitting:", emitters)
end