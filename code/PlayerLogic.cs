using Sandbox;
using Sandbox.UI;


public sealed class PlayerLogic : Component
{
	
	[Property] public BasicCrosshairUI _BasicCrosshair;
	
	 public BasicCrosshairUI Crosshair;

	protected override void OnStart()
	{
		Crosshair = _BasicCrosshair.Components.Get<BasicCrosshairUI>();
	}


	protected override void OnUpdate()
	{
		if ( Input.Down( "attack1" ) )
		{
			Crosshair.OnShoot();
		}
		if ( Input.Released( "attack1" ) )
		{
			Crosshair.StopShoot();
		}
		
	}
}
