using System.Collections.Generic;
using Sandbox;

public sealed class TraceLaser : Component
{
	
	[Property] public float TraceLength { get; set; } = 1000;

	private LineRenderer _lineRenderer => Components.Get<LineRenderer>();
	[Property] private GameObject endpos;
	
	protected override void OnUpdate()
	{
		
		DrawGizmos();
	}

	protected override void DrawGizmos()
	{
		
		Gizmo.Transform = global::Transform.Zero;
		var tr = Scene.Trace.Ray( new Ray( WorldPosition, WorldRotation.Right ), TraceLength );
		var r = tr.Run();
		endpos.WorldPosition = r.EndPosition;


		// Gizmo.Draw.Color = Color.Magenta;
		// Gizmo.Draw.LineThickness = 1;
		// Gizmo.Draw.Line( r.StartPosition, r.EndPosition );

	}
}
