uniform float time;
uniform vec3 camPos;

in vec4 FragPos;

float sdfSphere(vec3 p, float r)
{
    return length(p) - r;
}

float sdfSphere2(vec3 p, float r)
{
    return min(min( (length(p-copter1) - r), (length(p-copter2) - r )), (length(p-copter3) - r ));
}


void main()
{
    vec3 rayDir = normalize(FragPos.xyz - camPos.xyz);
    vec3 pos = camPos.xyz;
    float t = 0.0;
    bool hit = false;
    for(int i = 0; i < 100; i++)
    {
        pos = camPos.xyz + rayDir * t;
        float dist = sdfSphere(pos, 1.0);
        t += dist;
        if(dist < 0.001)
        {
            hit = true;
            break;
        }
        if(dist > 100.0)
        {
            break;
        }
    }
    if(hit)
    {
        gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
    }
    else
    {
        discard;
    }

}