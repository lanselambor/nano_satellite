
/*
  文件：processing_satelite_sys.pde 
*/
  
import processing.serial.*;
import controlP5.*;

// float _scale = 0.78125;
public float _scale = 1.5;

/**
 * @brief Components layout
 */  
int coor_zero_point = 0;
int[] coor_longitude = {int(38*_scale), coor_zero_point + int(30*_scale)};
int[] coor_latitude = {int(300*_scale), coor_zero_point + int(30*_scale)};
int[] coor_satellite = {int(700*_scale), coor_zero_point + int(140*_scale), int(50 * _scale)};
int[] coor_pic = {int(30*_scale), coor_zero_point + int(57*_scale)};
int[] coor_compass = {int(620*_scale), coor_zero_point + int(260*_scale)};
int[] coor_dashBoard = {int(600*_scale), coor_zero_point + int(240*_scale)};
int[] coor_thermometer = {int(800*_scale), coor_zero_point + int(250*_scale)};
int[] coor_humidity = {int(900*_scale), coor_zero_point + int(250*_scale)};
int[] coor_button = {int(600*_scale), coor_zero_point + int(470*_scale)};
int[] coor_serialPortConfig = {int(853*_scale), coor_zero_point + int(20*_scale)};
int[] coor_RFchannelConfig = {int(855*_scale), coor_zero_point + int(168*_scale)};
int[] coor_RFchannelConfigButton = {int(956*_scale), coor_zero_point + int(165*_scale)};
int[] coor_terminal = {int(38*_scale), coor_zero_point + int(460*_scale)};

/**
 * @brief Button layout
 */
int g_ibutton_width = int(80 * _scale);
int g_ibutton_height = int(50 * _scale);
int g_ibutton_gap = g_ibutton_width + int(25 * _scale);
int g_itext_gap = g_ibutton_height + int(15 * _scale);
int[] g_ibutton1 = {coor_button[0], coor_button[1]};
int[] g_ibutton2 = {coor_button[0] + 1 * g_ibutton_gap, coor_button[1]};
int[] g_ibutton3 = {coor_button[0] + 1 * g_ibutton_gap + g_ibutton_width / 2, coor_button[1]};
int[] g_ibutton4 = {coor_button[0] + 2 * g_ibutton_gap, coor_button[1]};
int[] g_ibutton5 = {coor_button[0] + 2 * g_ibutton_gap + g_ibutton_width / 2, coor_button[1]};
int[] g_ibutton6 = {coor_button[0] + 3 * g_ibutton_gap, coor_button[1]};

/**
 * @brief 空间尺寸
 */
int [] g_Size_screen = {int(1024 * _scale), int(560 * _scale)};
int [] g_cp5Size_channel_input = {int(85 * _scale), int(26 * _scale)};
int [] g_cp5Size_channel_set_button = {int(43 * _scale),  int(50 * _scale)};
int [] g_cp5Size_terminal = {int(500 * _scale), int(80 * _scale)};
int [] g_cp5Size_port_DropDownList = {int(145 * _scale),  int(120 * _scale)};
int [] g_Size_compass = {int(160 * _scale), int(160 * _scale)};
int [] g_Size_background_img = {int(1024 * _scale), int(560 * _scale)};
/**
 * @brief image and shape
 */
PShape satellite;
PShape thermometer;
PShape humidity;
PImage compass;
PImage compass_arrow;
PImage img;
PImage bg;

// Components
Serial myPort;
ControlP5 cp5;
DropdownList COM_List;
Textarea terminal;
Label RF_set_button;
Textfield RF_set_input;
String log_content = "";

// 系统全局变量
public float cur_pos_x = 0;
public float cur_pos_y = 0;
public float cur_pos_z = 0;
public float dist_pos_x = 0;
public float dist_pos_y = 0;
public float dist_pos_z = 0;
public float cur_compass = 0;
public boolean g_is_start_heater = false;
public boolean g_is_solar_pannel_opened = false;
public int   pic_load_percent = 0;   // 图片加载进程
public boolean kill_pic_receive_processing = false;  // 强制退出传输图片进程
public long time_begin_get_sensor_data = millis();  // 收取传感器数据的开始时间变量
public boolean receiving_pic_intterupt = false;

public final int OPT_DEFAULT = 0;
public final int OPT_TAKE_PHOTO = 1;
public final int OPT_TURN_ON_HEATER = 2;
public final int OPT_TURN_OFF_HEATER = 3;
public final int OPT_OPEN_SOLAR_PANEL = 4;
public final int OPT_CLOSE_SOLAR_PANEL = 5;
public final int OPT_REQUEST_SAT_DATA = 6;
public final int OPT_PRE_CAPTUR = 7;
public final int OPT_GET_PIC_LEN = 8;
public final int OPT_RECEIVE_PIC_DATA = 9;
public final int OPT_RESET = 10;
public boolean is_opt_busy = false;
public boolean is_setting_RF_channel = false;
public int opt_index = OPT_REQUEST_SAT_DATA;
public String RF_CHN = "";

OutputStream picture;

Satellite_SYS sat_sys = new Satellite_SYS();


void setup() {
  fullScreen(P3D);
  /* 检测显示器大小， 调整分辨率 */
  _scale = width / 1024.0;
  coor_zero_point = int((height - 560 * _scale) / 2);
  resize_components(_scale);
  

  
  
  cp5 = new ControlP5(this);

  /* 扫描串口 */
  scan_serial_ports();
  // RF_channel_list_init();

  /* RF信道设置输入框 */
  RF_set_input = cp5.addTextfield("RF_CHN")
    .setPosition(coor_RFchannelConfig[0], coor_RFchannelConfig[1])
    .setSize(g_cp5Size_channel_input[0], g_cp5Size_channel_input[1])  // 设置大小
    .setFont(createFont("arial", int(13 * _scale)))
    .setAutoClear(false)
    .setFocus(true)
    .setColor(color(255,255,0))
    ;

  /* RF信道设置按钮 */
  RF_set_button = cp5.addBang("RFset")
     .setPosition(coor_RFchannelConfigButton[0], coor_RFchannelConfigButton[1])
     .setSize(g_cp5Size_channel_set_button[0], g_cp5Size_channel_set_button[1])
     .setFont(createFont("arial",int(12 * _scale)))
     .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
     .setColor(color(255,255,255))
     ;

  /* 信息打印窗口 */
  terminal = cp5.addTextarea("txt")
             .setPosition(coor_terminal[0], coor_terminal[1])
             .setSize(g_cp5Size_terminal[0], g_cp5Size_terminal[1])
             .setFont(createFont("arial", int(14 * _scale)))
             .setLineHeight(int(14 * _scale))
             .setColor(color(200))
             .setColorBackground(color(0))
             .setColorForeground(color(0))
             ;
   System_Log("Study the satellite theory!\r\nStarting system...");

  /* 初始化模型和背景 */
  try {
    img = loadImage("pic.jpg");  /* 卫星照片 */
  } catch (Exception e) {

  }
  
  //image(img, coor_pic[0], coor_pic[1], img.width*0.8, img.height*0.8); // 显示图片
  satellite = loadShape("bracket_box_2_0.obj"); /* 卫星3D模型 */
  thermometer = loadShape("thermometer.svg");  /* 温度计图形 */
  humidity = loadShape("thermometer.svg");  /* 温度计图形 */
  //bg = loadImage("metel.png"); /* 背景图 */
  bg = loadImage("background.png"); /* 背景图 */
  compass = loadImage("compass.png");  /* 指南针底盘 */
  compass_arrow = loadImage("compass_arrow.png");  /* 指南针指针 */
  

  System_Log("Initialize successfully!\r\n" + 
              "Please connect the right serial port of wireless RF model!");
}

// float axis = 0;
/**
 * @ Draw method
 */
void draw() {
  bg.resize(int(1024 * _scale), int(560 * _scale));
  resize_components(_scale);
  
  //background(bg);  /* 加载背景图 */
  image(bg, 0, coor_zero_point, g_Size_background_img[0], g_Size_background_img[1]);
  
  stroke(255);  /* 边缘为白色 */
  fill(0);  /* 填充颜色为纯黑色 */
  
  /* 图形、图片、数据刷新 */ 
  //gps_coordinate(19.646334, 110.988356); /* GPS 数据显示 */
  gps_coordinate(sat_sys.gps_LON, sat_sys.gps_LAT); /* GPS 数据显示 */
  ///gps_coordinate(sat_sys.gps_LON, sat_sys.gps_LAT); /* GPS 数据显示 */
  draw_picture();  /* 显示卫星照片 */
  draw_compass(sat_sys.compass_value);  /* 指南针 */
  draw_temp_and_humi(sat_sys.heating_temp, sat_sys.inside_humi);  /* 温湿度 */
  //draw_temp_and_humi(g_fvirtual_temp, sat_sys.inside_humi);  /* 温湿度 */
  
  cal_gradual_data();
  // draw_satellitePosture(-cur_pos_y, -cur_pos_x, 1.0);  /* 卫星姿态 */
  // draw_satellitePosture(-cur_pos_x, cur_pos_y, sat_sys.compass_value/360.0*TWO_PI+HALF_PI);  /* 卫星姿态 */
  draw_satellitePosture(-cur_pos_x, cur_pos_y,  -1.0);  /* 卫星姿态 */
  drawButtons();  /* 按键 */
  
  terminal.setText(log_content);

}

void resize_components(float _scale) {

  coor_longitude[0] = int(38*_scale);
  coor_longitude[1] = coor_zero_point + int(30*_scale);
  coor_latitude[0] = int(300*_scale);
  coor_latitude[1] = coor_zero_point + int(30*_scale);
  coor_satellite[0] = int(700*_scale);
  coor_satellite[1] = coor_zero_point + int(140*_scale);
  coor_satellite[2] = int(50 * _scale);
  coor_pic[0] = int(30*_scale);
  coor_pic[1] = coor_zero_point + int(57*_scale);
  coor_compass[0] = int(620*_scale);
  coor_compass[1] = coor_zero_point + int(260*_scale);
  coor_dashBoard[0] = int(600*_scale);
  coor_dashBoard[1] = coor_zero_point + int(240*_scale);
  coor_thermometer[0] = int(800*_scale);
  coor_thermometer[1] = coor_zero_point + int(250*_scale);
  coor_humidity[0] = int(900*_scale);
  coor_humidity[1] = coor_zero_point + int(250*_scale);
  coor_button[0] = int(600*_scale);
  coor_button[1] = coor_zero_point + int(470*_scale);
  coor_serialPortConfig[0] = int(853*_scale);
  coor_serialPortConfig[1] = coor_zero_point + int(20*_scale);
  coor_RFchannelConfig[0] = int(855*_scale);
  coor_RFchannelConfig[1] = coor_zero_point + int(168*_scale);
  coor_RFchannelConfigButton[0] = int(956*_scale);
  coor_RFchannelConfigButton[1] = coor_zero_point + int(165*_scale);
  coor_terminal[0] = int(38*_scale);
  coor_terminal[1] = coor_zero_point + int(460*_scale);

  g_ibutton_width = int(80 * _scale);
  g_ibutton_height = int(50 * _scale);
  g_ibutton_gap = g_ibutton_width + int(25 * _scale);
  g_itext_gap = g_ibutton_height + int(15 * _scale);
  g_ibutton1[0] = coor_button[0];
  g_ibutton1[1] = coor_button[1];
  g_ibutton2[0] = coor_button[0] + 1 * g_ibutton_gap;
  g_ibutton2[1] = coor_button[1];
  g_ibutton3[0] = coor_button[0] + 1 * g_ibutton_gap + g_ibutton_width / 2;
  g_ibutton3[1] = coor_button[1];
  g_ibutton4[0] = coor_button[0] + 2 * g_ibutton_gap;
  g_ibutton4[1] = coor_button[1];
  g_ibutton5[0] = coor_button[0] + 2 * g_ibutton_gap + g_ibutton_width / 2;
  g_ibutton5[1] = coor_button[1];
  g_ibutton6[0] = coor_button[0] + 3 * g_ibutton_gap;
  g_ibutton6[1] = coor_button[1];

  g_Size_screen[0] = int(1024 * _scale);
  g_Size_screen[1] = int(560 * _scale);
  g_cp5Size_channel_input[0] = int(85 * _scale);
  g_cp5Size_channel_input[1] = int(26 * _scale);
  g_cp5Size_channel_set_button[0] = int(43 * _scale);
  g_cp5Size_channel_set_button[1] =  int(50 * _scale);
  g_cp5Size_terminal[0] = int(500 * _scale);
  g_cp5Size_terminal[1] = int(80 * _scale);
  g_cp5Size_port_DropDownList[0] = int(145 * _scale);
  g_cp5Size_port_DropDownList[1] =  int(120 * _scale);
  g_Size_compass[0] = int(160 * _scale);
  g_Size_compass[1] = int(160 * _scale);
  g_Size_background_img[0] = int(1024 * _scale);
  g_Size_background_img[1] = int(560 * _scale);
}


/**
 * @函数: void cal_gradual_data()
 * @说明: 姿态数据渐变处理
 */
void cal_gradual_data() {

  if(cur_pos_x < (-sat_sys.rotate_x)) cur_pos_x += 0.02;
  if(cur_pos_y < (-sat_sys.rotate_y)) cur_pos_y += 0.02;
  
  if(cur_pos_x > (-sat_sys.rotate_x)) cur_pos_x -= 0.02;
  if(cur_pos_y > (-sat_sys.rotate_y)) cur_pos_y -= 0.02;
}

/**
 * @函数:  
 * @说明:
 */


/** 
 * @函数：public void System_Log()
 */
public void System_Log(String str) {
  log_content = str;
}

public void RFset() {
  int error_cnt = 0;

  is_setting_RF_channel = true;
  System_Log("Setting RF channel...");

  String channel = cp5.get(Textfield.class,"RF_CHN").getText();
  println("Set RF channel: " + channel);

  while (0 != test_RF_config_mode()) {
    if(5 < (error_cnt++)) {
      System_Log("Test RF setting error!");
      is_setting_RF_channel = false;
      return;
    }
  }

  if (0 == config_RF_channel(channel)) {
    System_Log("Set RF channel: " + channel);
  } else {
    System_Log("Set RF channel error!");
  }

  is_setting_RF_channel = false;
}

/**
 * @函数: int get_pic_data()
 * @返回值: 0代表拍照失败, 1代表拍照成功
 */
int get_pic_data() 
{
  println("Receiving pic!");
  picture = createOutput("pic.jpg");
  
  final int dataSize = 127;

  sat_sys.myPort.clear();
  sat_sys.myPort.write(sat_sys.COMM_RECEIVE_PIC_DATA);
  
  delay(100);
  if (sat_sys.RF_read_timeout(1000)) {
    return -1;
  }

  int data = sat_sys.myPort.read();
  println("Received data back: " + data);
  
  if(data != sat_sys.COMM_RECEIVE_PIC_DATA) {
    return -2;
  } 

  if (data == sat_sys.COMM_RECEIVE_PIC_DATA) {
    // Start receive pic data
    long data_len_saved = 0;
    int error_counter = 0;    

    while(sat_sys.pic_length > data_len_saved) {
      int[] dataBuffer = new int[dataSize];
      int checksum = 0;
      int sum = 0;
      
      // 检查系统是否要求停止接收图片
      if( receiving_pic_intterupt ){
        receiving_pic_intterupt = false;
        println("Receiveing pic interrupt...");
        System_Log("Receiveing pic interrupt...");
        return -3;
      }
      opt_index = OPT_RESET;
      // 1.读取 dataSize Bytes
      //while(sat_sys.myPort.available() < 128);
      for(int i = 0; i < dataSize; i++){
        if(sat_sys.RF_read_timeout(1000)){

          println("Read dataSize bytes timeout!");

          // 超时等待次数过多，退出本次传输，重新传输
          if(5 <= ( error_counter++ ) ) {
            sat_sys.myPort.write(sat_sys.COMM_CAN);
            return -1;
          }
          // 超时重发
          sat_sys.myPort.write(sat_sys.COMM_NAK);
          delay(100);
          i = 0;
          sum = 0;
          continue;
        }
        dataBuffer[i] = sat_sys.myPort.read();
        // data_len_received ++;
        sum += dataBuffer[i];
        sum = sum % 0xFF;
      }
      // 错误次数清零
      error_counter = 0;
      

      // 2.等待校验和到来
      if (sat_sys.RF_read_timeout(1000)) { // 等待校验和
        println("Waiting for checksum timeout!");
        sat_sys.myPort.write(sat_sys.COMM_NAK);
        continue;
      }

      // 3.读取校验和
      checksum = sat_sys.myPort.read();  // 读取校验和

      // 4.检查校验和
      if(sum != checksum) {  // 判断校验和
        sat_sys.myPort.clear();  // 清除串口缓存
        sat_sys.myPort.write(sat_sys.COMM_NAK); // 校验和不对，发送重发命令
        println("Checksum error!");
        continue;
      }

      sat_sys.myPort.write(sat_sys.COMM_ACK);  // 发送正确回应，让卫星继续发送后继数据。

      // 5.储存图片数据
      if (data_len_saved <= sat_sys.pic_length) {
        for (int i = 0; i < dataSize; i++) {
          try {
            picture.write(dataBuffer[i]);  // 写入 dataSize 字节数据
            data_len_saved ++;
          } 
          catch (IOException e) {
            // e.printStackTrace();
          }
        }
      } else {
        for (int i = 0; i < (sat_sys.pic_length + dataSize - data_len_saved); i++) {
          try {
            picture.write(dataBuffer[i]);  // 写入 dataSize 字节数据
            data_len_saved ++;
          } 
          catch (IOException e) {
            // e.printStackTrace();
          } // 写入最后不到dataSize字节的数据
          data_len_saved ++;
        }
        break;
      }
      // sat_sys.myPort.write(sat_sys.COMM_ACK);  // 发送正确回应，让卫星继续发送后继数据。
      
      pic_load_percent = (int)(data_len_saved*100/sat_sys.pic_length);
      println("data_received: " + pic_load_percent + "%");
      log_content = "Receiveing picture: " + pic_load_percent + "%";
      try {
        img = loadImage("pic.jpg");  // 加载图片
      } catch (Exception e){
        // e.printStackTrace();
      }
    }
  }
  
  return 0;
} /* End of get_pic_data() */
    


/**
 * @brief Serial port init
 */
void customize(DropdownList ddl, ArrayList<String> list) {
  // a convenience function to customize a DropdownList
  ddl.setBackgroundColor(color(0));
  ddl.setItemHeight(30);
  ddl.setBarHeight(25);
  for (int i=0;i<list.size();i++) {
    ddl.addItem(list.get(i), null);
  }
  ddl.setColorBackground(color(0));
  ddl.setColorActive(color(255, 128));
}


/**
 * @函数：void controlEvent(ControlEvent theEvent)
 */
void controlEvent(ControlEvent theEvent) {
  // if(theEvent.isAssignableFrom(Textfield.class)) {
  //   println("controlEvent: accessing a string from controller '"
  //           +theEvent.getName()+"': "
  //           +theEvent.getStringValue()
  //           );

  //   // Add String value to RF CHN variable
  // } 
  if (theEvent.isController()) {
    if (COM_List == theEvent.getController()) {
      println("Select port : " + int(theEvent.getController().getValue()));
      config_serial_port(int(theEvent.getController().getValue()));
    }
  }
}

/**
 * @函数：int test_RF_config_mode()
 */
int test_RF_config_mode() {
  String inStrng = "";
  
  myPort.clear();
  myPort.write("AT");
  if (serial_read_timeout(500) ){
    return -1;
  } else {
    while (myPort.available() > 0) {
      inStrng += myPort.readChar();
      delay(1);
    }
  }
  
  if((null == inStrng) || !inStrng.contains("OK")) {
    return -1;
  }
  
  return 0;

}

/**
 * @函数：int config_RF_channel(int channel)
 * @说明：设置无线模块的通讯信道
 * @参数：channel 信道
 */
int config_RF_channel(String channel) {
  String inString = "";

  if(channel.length() != 4) {
    return -1;
  }

  myPort.write("AT+" + channel);
  println("config_RF_channel: " + "AT+" + channel);

  if (serial_read_timeout(1000) ){
    return -1;
  } else {
    while (myPort.available() > 0) {
      inString += myPort.readChar();
      delay(3);
    }
  }

  System_Log("RF channel setting: " + inString);
  if(!inString.contains(channel)) {
    return -1;
  }
  
  return 0;
}

/**
 * @函数：void config_serial_port(int index)
 */
void config_serial_port(int index) {
  println("config serial port");
  // myPort = new Serial( this, Serial.list()[index], 115200);
  myPort = new Serial( this, Serial.list()[index], 9600);
  myPort.clear();
  sat_sys.myPort = myPort;

  System_Log("Connecting satelite...");

  thread("thread_RF_Serial");

}

/**
 * @函数：boolean serial_read_timeout(long timeout)
 * @参数：timeout: 毫秒
 * @说明：等待串口数据，超时返回
 */
boolean serial_read_timeout(long timeout) {
  long time_start = millis();

  while(myPort.available() <= 0) {
    delay(5);
    if(timeout < millis() - time_start) {
      return true;
    }
  }

  return false;
}

/**
 * @函数：void thread_RF_Serial()
 * @说明：无线串口数据处理线程
 */
void thread_RF_Serial() {
  while(true) {
    int ret = -1;
    int cnt = 0;

    if(is_setting_RF_channel) {
      delay(1000);
      continue;
    }

    switch (opt_index) {

      case OPT_DEFAULT:
        break;

      case OPT_PRE_CAPTUR:
        System_Log("Taking photo...");
        // whlie(0 != ret && (cnt--)){}
        ret = sat_sys.take_photo_precapture();
        print("Pre-capture result: ");
        println(ret);
        opt_index = OPT_GET_PIC_LEN;
        break;

      case OPT_GET_PIC_LEN:
        cnt = 10;
        while((0 != ret) && ( 0 != cnt--)){
          // Check if reset button pressed
          if( receiving_pic_intterupt ) {
            receiving_pic_intterupt = false;
            opt_index = OPT_REQUEST_SAT_DATA;
            break;
          }

          ret = sat_sys.get_pic_len();
          if(-2 == ret) {
            opt_index = OPT_REQUEST_SAT_DATA;
            break;
          }
          print("Get pic length result: ");
          println(ret);
          delay(500);
        }
        if(ret == 0) {
          opt_index = OPT_RECEIVE_PIC_DATA;
        } else {
          opt_index = OPT_REQUEST_SAT_DATA;
        }
        break;

      case OPT_RECEIVE_PIC_DATA:
        opt_index = OPT_REQUEST_SAT_DATA;
        System_Log("Begin receiveing picture...");
        //ret = sat_sys.receive_pic_data();
        ret = get_pic_data();
        print("Receive pic result: ");
        println(ret);

        if (0 != ret) {
          System_Log("Failed to receive picture!");
          println("Get photo error!");
          opt_index = OPT_RESET;
        } else if(-3 == ret) {
          opt_index = OPT_RESET;
        } else {
          img = loadImage("pic.jpg");
          System_Log("Get picture succeed!");
        }
        break;

      case OPT_TURN_ON_HEATER:
        opt_index = OPT_REQUEST_SAT_DATA;
        System_Log("Opening heater...");
        ret = sat_sys.open_heater();  
        
        if(0 == ret) {
          System_Log("Open heater succeed...");
          g_is_start_heater = true;
        } else {
          System_Log("Open heater failed...");
        }
        break;

      case OPT_TURN_OFF_HEATER:
        opt_index = OPT_REQUEST_SAT_DATA;
        System_Log("Closing heater...");
        ret = sat_sys.close_heater();

        if(0 == ret) {
          System_Log("Close heater succeed...");
          g_is_start_heater = false;
        } else {
          System_Log("Close heater failed...");
        }
        break;

      case OPT_OPEN_SOLAR_PANEL:
        opt_index = OPT_REQUEST_SAT_DATA;
        System_Log("Opening solar panel...!");        
        ret = sat_sys.open_solar_panel();
        g_is_solar_pannel_opened = true;
        print("Open solar panel result: ");
        println(ret);
        if(0 == ret) {
          System_Log("Opene solar panel succeed!");        
        } else {
          System_Log("Opene solar panel failed...");        
        }

        break;

      case OPT_CLOSE_SOLAR_PANEL:
        opt_index = OPT_REQUEST_SAT_DATA;
        System_Log("Closing solar panel...!");
        ret = sat_sys.close_solar_panel();
        g_is_solar_pannel_opened = false;
        print("Close solar panel result: ");
        println(ret);
        if(0 == ret) {
          System_Log("Close solar panel succeed!");        
        } else {
          System_Log("Close solar panel failed...");        
        }        
        break;

      case OPT_RESET:
        System_Log("Reset system!");
        // 1.发送COMM_CAN 退出所有任务，包括拍照
        myPort.write(sat_sys.COMM_CAN);
        delay(1000);

        // 2.关闭加热板
        System_Log("Closing heater...");
        ret = sat_sys.close_heater();

        if(0 == ret) {
          System_Log("Close heater succeed...");
          g_is_start_heater = false;
        } else {
          System_Log("Close heater failed...");
        }
        delay(500);

        // 3.关闭太阳能板
        System_Log("Closing solar panel...!");
        ret = sat_sys.close_solar_panel();
        g_is_solar_pannel_opened = false;
        print("Close solar panel result: ");
        println(ret);
        if(0 == ret) {
          System_Log("Close solar panel succeed!");        
        } else {
          System_Log("Close solar panel failed...");        
        }
        
        println("System Reset!");
        opt_index = OPT_REQUEST_SAT_DATA;
        break;

      case OPT_REQUEST_SAT_DATA:
        if (1000 < (millis() - time_begin_get_sensor_data)) {
          time_begin_get_sensor_data = millis();
          ret = sat_sys.get_Sensor_data(1000);  // 获取传感器数据
          print("Get date state: ");
          println(ret);
          if (0 == ret) {
  
            System_Log(
                     "Temperature: " + sat_sys.heating_temp +
                     "  Humidity: " + sat_sys.inside_humi + 
                     "  Compass: " + sat_sys.compass_value + "\n" +
                     "Sate_posture: " + sat_sys.rotate_x + "  " +sat_sys.rotate_y + "  " + sat_sys.rotate_z + "\r\n" + 
                     "GPS_LAT: " + sat_sys.gps_LAT + ", GPS_LON: " + sat_sys.gps_LON
                     );
          }
        }
        break;

      default: break;
    }
  }  
}

/**
 * @函数：void scan_serial_ports()
 * @
 */
void scan_serial_ports() {
  ArrayList<String> port_list = new ArrayList<String>();
  String[]  temp_list = {};
  
  temp_list = Serial.list();
  if( 0 == temp_list.length ) {
    textSize(12);
    fill(230);
    text("No serial port found", coor_serialPortConfig[0] + 10, coor_serialPortConfig[1] + 20);
    return;
  }

  for (int i = 0; i < temp_list.length; i++) {
    if (temp_list[i].contains("/dev/cu") || temp_list[i].contains("COM")) {
      port_list.add(temp_list[i]);
    }
  }
  
  //printArray(port_list);
  COM_List = cp5.addDropdownList("SELECT PORT")
                .setPosition(coor_serialPortConfig[0], coor_serialPortConfig[1])
                .setFont(createFont("arial", int(10 * _scale)))
                .setSize(g_cp5Size_port_DropDownList[0], g_cp5Size_port_DropDownList[1])
                ;

  customize(COM_List, port_list);
  
}

/**
 * @函数：void mouseReleased()
 * @返回值：无
 * @说明：监测鼠标右击松开时的位置，用来实现鼠标点击的功能反馈  
 */
void mouseReleased() {

  if (mouseIn(g_ibutton1[0], g_ibutton1[1], g_ibutton1[0] + g_ibutton_width, g_ibutton1[1] + g_ibutton_height)) {
    // opt_index = OPT_TAKE_PHOTO;
    opt_index = OPT_PRE_CAPTUR;
  }
  if (mouseIn(g_ibutton2[0], g_ibutton2[1], g_ibutton2[0] + g_ibutton_width / 2, g_ibutton2[1] + g_ibutton_height)) {
    opt_index = OPT_OPEN_SOLAR_PANEL;

  }
  if (mouseIn(g_ibutton3[0], g_ibutton3[1], g_ibutton3[0] + g_ibutton_width / 2, g_ibutton3[1] + g_ibutton_height)) {
    opt_index = OPT_CLOSE_SOLAR_PANEL;

  }
  if (mouseIn(g_ibutton4[0], g_ibutton4[1], g_ibutton4[0] + g_ibutton_width / 2, g_ibutton4[1] + g_ibutton_height)) {
    opt_index = OPT_TURN_ON_HEATER;

  }
  if (mouseIn(g_ibutton5[0], g_ibutton5[1], g_ibutton5[0] + g_ibutton_width / 2, g_ibutton5[1] + g_ibutton_height)) {
    opt_index = OPT_TURN_OFF_HEATER;
  }
  //Reset
  if (mouseIn(g_ibutton6[0], g_ibutton6[1], g_ibutton6[0] + g_ibutton_width, g_ibutton6[1] + g_ibutton_height)) {
    opt_index = OPT_RESET;
    receiving_pic_intterupt = true;
  }
}


void drawButtons() {
  color release = color(0, 200, 0);
  color touch = color(200, 0, 0);
  color c1 = release;
  color c2 = release;
  color c3 = release;
  color c4 = release;
  color c5 = release;
  color c6 = release;
  

  if (mouseIn(g_ibutton1[0], g_ibutton1[1], g_ibutton1[0] + g_ibutton_width, g_ibutton1[1] + g_ibutton_height)) {
    c1 = touch;
  }
  if (mouseIn(g_ibutton2[0], g_ibutton2[1], g_ibutton2[0] + g_ibutton_width / 2, g_ibutton2[1] + g_ibutton_height)) {
    c2 = touch;
  }
  if (mouseIn(g_ibutton3[0], g_ibutton3[1], g_ibutton3[0] + g_ibutton_width / 2, g_ibutton3[1] + g_ibutton_height)) {
    c3 = touch;
  }
  if (mouseIn(g_ibutton4[0], g_ibutton4[1], g_ibutton4[0] + g_ibutton_width / 2, g_ibutton4[1] + g_ibutton_height)) {
    c4 = touch;
  } 
  if (mouseIn(g_ibutton5[0], g_ibutton5[1], g_ibutton5[0] + g_ibutton_width / 2, g_ibutton5[1] + g_ibutton_height)) {
    c5 = touch;
  }
  if (mouseIn(g_ibutton6[0], g_ibutton6[1], g_ibutton6[0] + g_ibutton_width, g_ibutton6[1] + g_ibutton_height)) {
    c6 = touch;
  }

  
  stroke(250);
  fill(c1);
  rect(g_ibutton1[0], g_ibutton1[1], g_ibutton_width, g_ibutton_height);
  
  if(true == g_is_solar_pannel_opened) {
    fill(touch);
  } else {
    fill(c2);  
  }
  rect(g_ibutton2[0], g_ibutton2[1], g_ibutton_width / 2, g_ibutton_height);
  
  if(true != g_is_solar_pannel_opened) {
    fill(touch);
  } else {
    fill(c3);
  }
  rect(g_ibutton3[0], g_ibutton3[1], g_ibutton_width / 2, g_ibutton_height);
  
  if(true == g_is_start_heater) {
    fill(touch);
  } else {
    fill(c4);
  }
  rect(g_ibutton4[0], g_ibutton4[1], g_ibutton_width / 2, g_ibutton_height);
 
  if(true != g_is_start_heater) {
    fill(touch);
  } else {
    fill(c5);
  }
  rect(g_ibutton5[0], g_ibutton5[1], g_ibutton_width / 2, g_ibutton_height);
  
  fill(c6);
  rect(g_ibutton6[0], g_ibutton6[1], g_ibutton_width, g_ibutton_height);
}

boolean mouseIn(int x1, int y1, int x2, int y2) {
  if ( (mouseX > x1) && (mouseX < x2) && (mouseY > y1) && (mouseY < y2)) {
    return true;
  } else {
    return false;
  }
}

private final float x_offset = HALF_PI;
private final float y_offset = 0;
private final float z_offset = 0;

void draw_satellitePosture(float rotate_x, float rotate_y, float rotate_z) {


  pushMatrix();
  translate(coor_satellite[0], coor_satellite[1], coor_satellite[2]);
  rotateX(rotate_x*HALF_PI + x_offset);
  rotateY(rotate_y*HALF_PI + y_offset);
  rotateZ(rotate_z*HALF_PI + z_offset);
  scale(5.0 * _scale);
  shape(satellite);
  popMatrix();
}

void draw_compass(float degree) {
  pushMatrix();
  translate(coor_compass[0], coor_compass[1]);
  image(compass, 0, 0, g_Size_compass[0], g_Size_compass[1]);
  popMatrix();
  pushMatrix();
  translate(coor_compass[0] + int(compass.width * _scale) / 4, coor_compass[1] + int(compass.height * _scale) / 4);
  rotateZ(degree/360.0*TWO_PI);
  translate(-int(compass.width * _scale)/4, -int(compass.height * _scale)/4);
  image(compass_arrow, 0, 0, g_Size_compass[0], g_Size_compass[1]);
  popMatrix();
}

void draw_picture() {
    if(img != null) {
      image(img, coor_pic[0], coor_pic[1], int(img.width*0.8*_scale), int(img.height*0.8*_scale));
    }
}

void draw_temp_and_humi(float temp, float humi) {
  String str_temp = String.format("%.2f", temp) + "C";
  String str_humi = String.format("%.2f", humi) + "%";
  fill(204, 0, 0);
  noStroke();
  textSize(int(20 * _scale));
  text(str_temp, coor_thermometer[0], coor_thermometer[1] + int(180 * _scale));
  text(str_humi, coor_humidity[0], coor_humidity[1] + int(180 * _scale));
  shape(thermometer, coor_thermometer[0], coor_thermometer[1], int(30 * _scale), int(150 * _scale));
  shape(humidity, coor_humidity[0], coor_humidity[1], int(30 * _scale), int(150 * _scale));
  rect(coor_thermometer[0] + int(10 * _scale), coor_thermometer[1] + int(132 * _scale) - int(temp * _scale), 5, int(temp * _scale));
  rect(coor_humidity[0] + int(10 * _scale), coor_humidity[1] + int(132 * _scale) - int(humi * _scale), 5, int(humi * _scale));
}

void gps_coordinate(float longitude, float latitude) {
  String str_longitude = "longitude:" + String.format("%.6f",longitude);
  String str_latitude = "latitude:" + String.format("%.6f",latitude);
  textSize(int(20 * _scale));
  fill(255, 0, 0);
  text(str_longitude, coor_longitude[0], coor_longitude[1]);
  text(str_latitude, coor_latitude[0], coor_latitude[1]);
}
// END FILE