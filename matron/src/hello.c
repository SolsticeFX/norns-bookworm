#include <math.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#include "events.h"
#include "oracle.h"
#include "screen.h"
#include "weaver.h"
#define LIGHTS 128
#define GRAVITY 2048
#define SPREAD 2

// thread id
static pthread_t tid;
// microseconds per frame
//static const int tick_us = 5000;
static const int tick_us = 5000;
// frames before timeout
static const int timeout_ticks = 2400; // ~12 seconds?

struct {
    double x;
    double y;
    double dx;
    double dy;
    int range;
    int life;
} light[LIGHTS];

struct {
    double x;
    double y;
    double dx;
    double dy;
} center;

struct {
    int x;
    int y;
} black;

struct {
    int r;
    int g;
    int b;
} rgbcolor;



static int count = 0;
static int start = 1;


static int timeout = 0;
static int ok = 0;
static volatile int thread_running = 0;

static int norns_hello();
static void *hello_loop(void *);
static void start_thread();

void *hello_loop(void *p) {
    (void)p;

    thread_running = true;

    while (!ok && !timeout) {

        norns_hello(1);
        o_query_startup();

        if (count > timeout_ticks) {
            timeout = 1;
        }

        usleep(tick_us);
        count++;
        // fprintf(stderr, "%d\n", count);
    }

    // fadeout
    while (norns_hello(0)) {
        usleep(tick_us);
    

    }

    if (timeout) {
        event_post(event_data_new(EVENT_STARTUP_READY_TIMEOUT));
    } else {
        event_post(event_data_new(EVENT_STARTUP_READY_OK));
        
    }

    thread_running = false;
    return NULL;
}

void start_thread() {
    // start thread
    int res;
    pthread_attr_t attr;

    res = pthread_attr_init(&attr);
    if (res != 0) {
        fprintf(stderr, "error creating pthread attributes\n");
        return;
    }
    res = pthread_create(&tid, &attr, &hello_loop, NULL);
    if (res != 0) {
        fprintf(stderr, "error creating pthread\n");
    }
}

void norns_hello_start() {
    if (thread_running) {
        return;
    }
    system("python3 /home/we/norns/scripts/boot.py");
    srand(time(NULL));
    screen_aa(1);
    screen_line_width(1);

    for (int i = 0; i < LIGHTS; i++) {
        light[i].range = 1;
    }

    black.x = 60 + rand() % 8;
    black.y = 28 + rand() % 8;
    center.x = 60 + rand() % 8;
    center.y = 28 + rand() % 8;
    center.dx = 0;
    center.dy = 0;
    count = 0;

    timeout = 0;
    ok = 0;

    start_thread();
}

void norns_hello_ok() {
    ok = 1;
    system("python3 /home/we/norns/scripts/postboot.py");
}

int norns_hello(int live) {

    if ((count & 255) == 0) {
        black.x = 60 + rand() % 8;
        black.y = 28 + rand() % 8;
    }

    screen_clear();


    // screen_line_width(1.0); // FIXME: for some reason setting this disables drawing

    center.dx = center.dx + (black.x - center.x) / GRAVITY;
    center.dy = center.dy + (black.y - center.y) / GRAVITY;
    center.x = center.x + center.dx;
    center.y = center.y + center.dy;
    int alive = 0;


    

    for (int i = 0; i < LIGHTS; i++) {
        if (light[i].range == 2) {
            if (start < 64 * SPREAD)
                start++;
            light[i].range--;
        } else if (light[i].range > 2) {
            light[i].range--;
            light[i].x += light[i].dx;
            light[i].y += light[i].dy;
            alive++;
            screen_rect(light[i].x, light[i].y, 1, 1);
/*
            int picker = (rand() % 3);
            if (picker == 0){
            screen_rgblevel(ceil(4 * light[i].range / light[i].life) * (start / 64.0), ceil(6 * light[i].range / light[i].life) * (start / 64.0), ceil(15 * light[i].range / light[i].life) * (start / 64.0));
            }
            else if (picker==1)
            {
screen_rgblevel(ceil(4 * light[i].range / light[i].life) * (start / 64.0), ceil(15 * light[i].range / light[i].life) * (start / 64.0), ceil(6 * light[i].range / light[i].life) * (start / 64.0));            }
else {
screen_rgblevel(ceil(15 * light[i].range / light[i].life) * (start / 64.0), ceil(4 * light[i].range / light[i].life) * (start / 64.0), ceil(6 * light[i].range / light[i].life) * (start / 64.0));            }
*/

            

            //screen_level(ceil(15 * light[i].range / light[i].life) * (start / 64.0));
            
            
            int r = 10+(rand() % 5);
            int g = 10+(rand() % 5);
            int b = 10+(rand() % 5);

            r = ceil(r * light[i].range / light[i].life) * (start / 64.0);
            g = ceil(g * light[i].range / light[i].life) * (start / 64.0);
            b = ceil(b * light[i].range / light[i].life) * (start / 64.0);

            double f = 3; // increase saturation
            double L = 0.3*r + 0.6*g + 0.1*b;

            rgbcolor.r = r - f * (L - r);
            rgbcolor.g =  g - f * (L - g);
            rgbcolor.b =  b - f * (L - b);


            screen_rgblevel(rgbcolor.r,rgbcolor.g ,rgbcolor.b );
            screen_stroke();
        } else if (live) {
            light[i].life = rand() % 64 * SPREAD;
            light[i].range = light[i].life;
            light[i].x = center.x;
            light[i].y = center.y;
            light[i].dx = (rand() % 32 - 16) / 96.0 * SPREAD;
            light[i].dy = (rand() % 32 - 16) / 96.0 * SPREAD;
        }
    }
    screen_update();

    return alive;
}
