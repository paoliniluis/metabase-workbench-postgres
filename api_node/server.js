import dgram from 'node:dgram';
import sql from './db.js'


const server = dgram.createSocket('udp4');

server.on('listening', () => {
    const address = server.address();
    console.log(`server listening ${address.address}:${address.port}`);
});

server.on('message', async (msg, rinfo) => {
    if (msg.includes('metabase')) {
        msg = msg.toString().split('.')[2].split(':');
        msg.length == 2 ? msg[1] = msg[1].slice(0,-2) : msg[1] = 0;
        msg[2] = new Date().toISOString();
        msg[0].includes('memory') ? msg[1] = msg[1] / 1024 / 1024 : null
        switch (msg[0]) {
            case 'memory_usage':
                msg[0] = 'memory_usage_in_mb'
            case 'memory_working_set':
                msg[0] = 'memory_working_set_in_mb'
        }

        if (msg[1] != 0) {
            await sql `
            INSERT INTO container_telemetry
            (client, metric_timestamp, metric_name, measure)
            VALUES
            (${rinfo.address}, ${ msg[2] }, ${ msg[0] }, ${ msg[1] })`
        } // client will always be the same, but just leaving that client ip there in case I have better ideas in the future
    }
});

server.on('error', (err) => {
    console.log(`server error:\n${err.stack}`);
    server.close();
});

server.bind(3000);