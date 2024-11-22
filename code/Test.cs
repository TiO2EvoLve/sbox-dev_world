using Sandbox;

public sealed class Test : Component
{

	[Property] public SoundEvent SoundEvent;
	protected override void OnUpdate()
	{
		if ( Input.Down( "use" ) )
		{
			Sound.Play( SoundEvent, Transform.Position );
		}
	}
}
