import { NextResponse, NextRequest } from 'next/server';
import { createClient } from '@supabase/supabase-js';

// Helper to get authenticated user from request
async function getAuthenticatedUser(req: NextRequest) {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) return null;
  
  const token = authHeader.substring(7);
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  );
  
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) return null;
  return { user, supabase };
}

export async function DELETE(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  // Check authentication
  const auth = await getAuthenticatedUser(req);
  if (!auth) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  
  const { id } = await params;
  const { supabase, user } = auth;

  try {
    // Verify user has permission to delete this team
    // Check if user is an admin of the organization that owns this team
    const { data: teamData, error: teamError } = await supabase
      .from('teams')
      .select('org_id')
      .eq('id', id)
      .single();
    
    if (teamError || !teamData) {
      return NextResponse.json({ error: 'Team not found' }, { status: 404 });
    }
    
    const { data: userMembership, error: memberError } = await supabase
      .from('organization_members')
      .select('role')
      .eq('org_id', teamData.org_id)
      .eq('user_id', user.id)
      .eq('status', 'active')
      .single();
    
    if (memberError || !userMembership || !['owner', 'admin'].includes(userMembership.role)) {
      return NextResponse.json({ error: 'Forbidden - insufficient permissions' }, { status: 403 });
    }

    const { error } = await supabase
      .from('teams')
      .delete()
      .eq('id', id);

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
