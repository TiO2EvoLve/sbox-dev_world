using Sandbox;

public sealed class RotionTest : Component
{

	[Property] private float Speed =0.1f;
	[Property] private Vector3 Axis = Vector3.Up;
	
	protected override void OnUpdate()
	{
		WorldRotation = WorldRotation.RotateAroundAxis( Axis, Speed);
	}
}
